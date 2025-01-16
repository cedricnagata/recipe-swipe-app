from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe as DBRecipe, SavedRecipe
from app.schemas.recipe import Recipe
from typing import List
from uuid import UUID
import logging

router = APIRouter(
    prefix="/saved-recipes",
    tags=["saved_recipes"]
)

@router.post("/{recipe_id}")
async def save_recipe(recipe_id: UUID, db: Session = Depends(get_db)):
    # Check if recipe exists
    recipe = db.query(DBRecipe).filter(DBRecipe.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    # Check if already saved
    existing = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
    if existing:
        return {"message": "Recipe already saved"}
    
    # Save the recipe
    saved_recipe = SavedRecipe(recipe_id=recipe_id)
    db.add(saved_recipe)
    db.commit()
    
    return {"message": "Recipe saved successfully"}

@router.get("/", response_model=List[Recipe])
async def get_saved_recipes(db: Session = Depends(get_db)):
    # Get all saved recipes with their full recipe data
    saved_recipes = (
        db.query(DBRecipe)
        .join(SavedRecipe, SavedRecipe.recipe_id == DBRecipe.id)
        .order_by(SavedRecipe.saved_at.desc())
        .all()
    )
    return saved_recipes

@router.get("/check/{recipe_id}")
async def check_if_saved(recipe_id: UUID, db: Session = Depends(get_db)):
    saved = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
    return {"is_saved": saved is not None}

@router.delete("/{recipe_id}")
async def unsave_recipe(recipe_id: UUID, db: Session = Depends(get_db)):
    saved_recipe = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
    if not saved_recipe:
        raise HTTPException(status_code=404, detail="Recipe not saved")
    
    db.delete(saved_recipe)
    db.commit()
    return {"message": "Recipe removed from saved recipes"}