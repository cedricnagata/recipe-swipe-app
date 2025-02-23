from openai import AsyncOpenAI
from app.core.config import settings
import json
from typing import List, Dict, Optional, Any
from app.schemas.cooking_session import Action, TimerAction, TemperatureAction

class AIService:
    def __init__(self):
        self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self.model = "gpt-4o-mini"

    def _create_step_analysis_prompt(self, recipe: Dict[str, Any], step_number: int) -> str:
        step = recipe["steps"][step_number]
        return f"""You are an AI chef analyzing steps in a recipe. For this step, identify any required timers or temperature settings.
Current step: "{step}"

You must return a JSON response containing any actions needed. Only include actions that are explicitly mentioned in the step.
For temperatures, only include numeric temperatures (like 350°F). Don't include descriptive temperatures like "medium heat".

Example response format:
{{
    "actions": [
        {{
            "type": "TIMER",
            "duration": 5,  # in minutes (must be a number)
            "appliance": "STOVE",  # must be: OVEN, STOVE, or OTHER
            "label": "Simmer sauce",  # short descriptive label
            "description": "Timer for simmering sauce"  # longer description
        }},
        {{
            "type": "TEMPERATURE",
            "appliance": "OVEN",  # must be: OVEN or STOVE
            "value": 350,  # temperature in fahrenheit (must be a number)
            "description": "Preheat oven to 350°F"  # descriptive text
        }}
    ]
}}

Only return valid JSON containing actions that have explicit numeric values. Do not include actions for descriptive temperatures like "medium heat" or "low heat"."""

    def _create_chat_prompt(self, recipe: Dict[str, Any], current_step: int, conversation_history: List[Dict], user_message: str) -> str:
        # Compile full recipe context
        full_context = f"Recipe: {recipe.get('title', 'Untitled Recipe')}\n\n"
        
        # Add full list of steps
        full_context += "All Recipe Steps:\n"
        for i, step in enumerate(recipe.get('steps', [])):
            full_context += f"{i+1}. {step}\n"
        
        # Add ingredients with amounts
        full_context += "\nIngredients:\n"
        for ingredient, amount in recipe.get('ingredients', {}).items():
            full_context += f"- {ingredient}: {amount}\n"
        
        # Current step details
        current_step_text = recipe["steps"][current_step] if current_step < len(recipe["steps"]) else "No current step"
        
        # Format conversation history
        formatted_history = "\n".join([
            f"{'User' if msg['role'] == 'user' else 'Assistant'}: {msg['content']}"
            for msg in conversation_history[-5:]  # Only include last 5 messages for context
        ])

        return f"""You are Little Chef, an AI cooking assistant helping someone cook a detailed recipe.
You have access to the full recipe context and current step.

{full_context}

Current detailed recipe context:
Current step: "{current_step_text}"

Previous conversation:
{formatted_history}

User: {user_message}

You can suggest actions like setting timers or temperatures if relevant to the user's question.
For temperatures, only include numeric temperatures (like 350°F). Don't suggest actions for descriptive temperatures like "medium heat".

Return your response in this JSON format:
{{
    "message": "your response text",
    "suggested_actions": [  # Optional - only include if suggesting actions
        {{
            "type": "TIMER",
            "duration": 5,  # in minutes (must be a number)
            "appliance": "STOVE",  # must be: OVEN, STOVE, or OTHER
            "label": "Simmer sauce",  # short descriptive label
            "description": "Timer for simmering sauce"  # longer description
        }}
    ]
}}"""

    def _validate_action(self, action: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Validate and clean up actions from AI response."""
        try:
            action_type = action.get("type")
            
            if action_type == "TIMER":
                duration = int(action.get("duration", 0))
                if duration <= 0:
                    return None
                    
                return {
                    "type": "TIMER",
                    "duration": duration,
                    "appliance": action.get("appliance", "OTHER").upper(),
                    "label": action.get("label", "Timer"),
                    "description": action.get("description", f"Timer for {duration} minutes")
                }
                
            elif action_type == "TEMPERATURE":
                value = action.get("value")
                if not isinstance(value, int) or value <= 0:
                    return None
                    
                return {
                    "type": "TEMPERATURE",
                    "value": value,
                    "appliance": action.get("appliance", "OVEN").upper(),
                    "description": action.get("description", f"Set temperature to {value}°F")
                }
                
        except (ValueError, TypeError):
            return None
            
        return None

    async def analyze_step(self, recipe: Dict[str, Any], step_number: int) -> List[Action]:
        """Analyze a recipe step and return suggested actions."""
        prompt = self._create_step_analysis_prompt(recipe, step_number)
        
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a helpful cooking assistant. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )

        try:
            result = json.loads(response.choices[0].message.content)
            actions = result.get("actions", [])
            
            # Validate and clean up each action
            valid_actions = []
            for action in actions:
                validated = self._validate_action(action)
                if validated:
                    valid_actions.append(validated)
                    
            return valid_actions
        except json.JSONDecodeError:
            return []

    async def chat(self, recipe: Dict[str, Any], current_step: int, 
                  conversation_history: List[Dict], user_message: str) -> Dict[str, Any]:
        """Handle a user message and return a response with optional suggested actions."""
        prompt = self._create_chat_prompt(recipe, current_step, conversation_history, user_message)
        
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are Little Chef, a helpful cooking assistant. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )

        try:
            result = json.loads(response.choices[0].message.content)
            
            # Validate and clean up any suggested actions
            suggested_actions = None
            if "suggested_actions" in result:
                valid_actions = []
                for action in result["suggested_actions"]:
                    validated = self._validate_action(action)
                    if validated:
                        valid_actions.append(validated)
                if valid_actions:
                    suggested_actions = valid_actions
            
            return {
                "message": result["message"],
                "suggested_actions": suggested_actions
            }
        except json.JSONDecodeError:
            return {
                "message": "I apologize, but I'm having trouble understanding. Could you please rephrase your question?",
                "suggested_actions": None
            }