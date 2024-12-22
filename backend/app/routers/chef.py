from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import ChefContext, Recipe, UserPreferences
from typing import Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel

router = APIRouter(
    prefix="/chef",
    tags=["chef"]
)

class ChefContextCreate(BaseModel):
    user_preferences_id: UUID
    current_recipe_id: Optional[UUID] = None
    current_step: Optional[Dict[str, Any]] = None
    session_data: Dict[str, Any] = {}

class ChefContextResponse(BaseModel):
    id: UUID
    user_preferences_id: UUID
    current_recipe_id: Optional[UUID]
    current_step: Optional[Dict[str, Any]]
    session_data: Dict[str, Any]

    class Config:
        from_attributes = True

@router.post("/start-session", response_model=ChefContextResponse)
def start_cooking_session(context: ChefContextCreate, db: Session = Depends(get_db)):
    # Verify that user preferences exist
    preferences = db.query(UserPreferences).filter(
        UserPreferences.id == context.user_preferences_id
    ).first()
    if not preferences:
        raise HTTPException(status_code=404, detail="User preferences not found")

    # Verify recipe if provided
    if context.current_recipe_id:
        recipe = db.query(Recipe).filter(Recipe.id == context.current_recipe_id).first()
        if not recipe:
            raise HTTPException(status_code=404, detail="Recipe not found")

    db_context = ChefContext(**context.model_dump())
    db.add(db_context)
    db.commit()
    db.refresh(db_context)
    return db_context

@router.get("/session/{context_id}", response_model=ChefContextResponse)
def get_session(context_id: UUID, db: Session = Depends(get_db)):
    context = db.query(ChefContext).filter(ChefContext.id == context_id).first()
    if not context:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    return context

@router.put("/session/{context_id}/step", response_model=ChefContextResponse)
def update_current_step(
    context_id: UUID,
    current_step: Dict[str, Any],
    db: Session = Depends(get_db)
):
    context = db.query(ChefContext).filter(ChefContext.id == context_id).first()
    if not context:
        raise HTTPException(status_code=404, detail="Cooking session not found")
    
    context.current_step = current_step
    db.commit()
    db.refresh(context)
    return context