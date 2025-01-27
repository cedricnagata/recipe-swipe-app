from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe as DBRecipe, SavedRecipe
from app.schemas.recipe import Recipe as RecipeSchema
from typing import List
from uuid import UUID

router = APIRouter(
    prefix="/saved-recipes",
    tags=["saved_recipes"]
)

@router.get("/", response_model=List[RecipeSchema])
async def get_saved_recipes(db: Session = Depends(get_db)):
    # Get all saved recipes with their full recipe data
    recipes = (
        db.query(DBRecipe)
        .join(SavedRecipe, SavedRecipe.recipe_id == DBRecipe.id)
        .order_by(SavedRecipe.saved_at.desc())
        .all()
    )
    
    # Create response with is_saved=True for all recipes
    recipe_responses = []
    for recipe in recipes:
        # Convert SQLAlchemy model to dict and add is_saved
        recipe_dict = {
            "id": recipe.id,
            "title": recipe.title,
            "ingredients": recipe.ingredients,
            "steps": recipe.steps,
            "source_url": recipe.source_url,
            "images": recipe.images,
            "total_time": recipe.total_time,
            "tags": recipe.tags,
            "hash": recipe.hash,
            "is_saved": True
        }
        recipe_responses.append(recipe_dict)
    return recipe_responses

@router.delete("/{recipe_id}")
async def unsave_recipe(recipe_id: UUID, db: Session = Depends(get_db)):
    saved_recipe = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
    if not saved_recipe:
        raise HTTPException(status_code=404, detail="Recipe not saved")
    
    db.delete(saved_recipe)
    db.commit()
    return {"message": "Recipe removed from saved recipes"}