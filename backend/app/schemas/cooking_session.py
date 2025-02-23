from pydantic import BaseModel, UUID4, Field
from typing import List, Optional, Union, Literal, Any, Dict
from datetime import datetime

class ActionBase(BaseModel):
    type: str
    appliance: str
    description: str

class TimerAction(ActionBase):
    type: Literal["TIMER"]
    duration: int = Field(description="Duration in minutes")
    label: str
    appliance: str = Field(description="OVEN, STOVE, or OTHER")

class TemperatureAction(ActionBase):
    type: Literal["TEMPERATURE"]
    value: Optional[int] = Field(description="Temperature in fahrenheit")
    appliance: str = Field(description="OVEN or STOVE")

Action = Union[TimerAction, TemperatureAction]

class Message(BaseModel):
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime
    suggested_actions: Optional[List[Action]] = None

class CookingSessionBase(BaseModel):
    recipe_id: UUID4
    current_step: int = 0

class CookingSessionCreate(CookingSessionBase):
    pass

class CookingSession(CookingSessionBase):
    id: UUID4
    conversation_history: List[Message]
    created_at: datetime
    last_updated: datetime

    class Config:
        from_attributes = True

# Request/Response schemas
class StepActionRequest(BaseModel):
    step_number: int

class StepActionResponse(BaseModel):
    actions: List[Action]

    class Config:
        json_encoders = {
            Action: lambda v: v.dict()
        }

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    message: str
    suggested_actions: Optional[List[Action]] = None