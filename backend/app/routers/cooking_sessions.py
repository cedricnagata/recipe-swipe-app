from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.cooking_session import CookingSession
from app.models.recipe import Recipe
from app.schemas.cooking_session import (
    CookingSessionCreate,
    CookingSession as CookingSessionSchema,
    StepActionRequest,
    StepActionResponse,
    ChatRequest,
    ChatResponse
)
from datetime import datetime
from typing import List
from app.services.ai_service import AIService
import uuid

router = APIRouter(prefix="/cooking-sessions", tags=["cooking-sessions"])

@router.post("/", response_model=CookingSessionSchema)
def create_cooking_session(
    session_create: CookingSessionCreate,
    db: Session = Depends(get_db)
):
    # Verify recipe exists
    recipe = db.query(Recipe).filter(Recipe.id == session_create.recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    cooking_session = CookingSession(
        recipe_id=session_create.recipe_id,
        current_step=session_create.current_step,
        conversation_history=[]
    )
    db.add(cooking_session)
    db.commit()
    db.refresh(cooking_session)
    return cooking_session

@router.post("/{session_id}/step_actions", response_model=StepActionResponse)
async def get_step_actions(
    session_id: uuid.UUID,
    request: StepActionRequest,
    db: Session = Depends(get_db)
):
    session = db.query(CookingSession).filter(CookingSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    
    # Update current step
    session.current_step = request.step_number
    db.commit()
    
    # Get recipe data
    recipe = db.query(Recipe).filter(Recipe.id == session.recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Use AI to analyze step
    ai = AIService()
    actions = await ai.analyze_step(recipe.__dict__, request.step_number)
    
    return StepActionResponse(actions=actions)

@router.post("/{session_id}/chat", response_model=ChatResponse)
async def chat_with_chef(
    session_id: uuid.UUID,
    request: ChatRequest,
    db: Session = Depends(get_db)
):
    session = db.query(CookingSession).filter(CookingSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    
    # Add user message to history
    if not session.conversation_history:
        session.conversation_history = []
    
    session.conversation_history.append({
        "role": "user",
        "content": request.message,
        "timestamp": datetime.utcnow().isoformat(),
        "suggested_actions": None
    })
    
    # Get recipe data
    recipe = db.query(Recipe).filter(Recipe.id == session.recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Use AI for chat response
    ai = AIService()
    response = await ai.chat(
        recipe.__dict__,
        session.current_step,
        session.conversation_history,
        request.message
    )
    
    # Add assistant response to history
    session.conversation_history.append({
        "role": "assistant",
        "content": response["message"],
        "timestamp": datetime.utcnow().isoformat(),
        "suggested_actions": response["suggested_actions"]
    })
    
    db.commit()
    return ChatResponse(**response)

@router.get("/{session_id}", response_model=CookingSessionSchema)
def get_cooking_session(
    session_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    session = db.query(CookingSession).filter(CookingSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    return session

@router.delete("/{session_id}")
async def delete_cooking_session(
    session_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    session = db.query(CookingSession).filter(CookingSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    
    db.delete(session)
    db.commit()
    return {"message": "Cooking session deleted"}