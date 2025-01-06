from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel
import logging
import random

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/recipes",
    tags=["recipes"]
)

class RecipeBase(BaseModel):
    title: str
    ingredients: dict
    steps: List[str]
    source_url: Optional[str] = None
    images: List[Optional[str]] = []

class RecipeCreate(RecipeBase):
    pass

class RecipeResponse(RecipeBase):
    id: UUID

    class Config:
        from_attributes = True

@router.post("/", response_model=RecipeResponse)
def create_recipe(recipe: RecipeCreate, db: Session = Depends(get_db)):
    db_recipe = Recipe(**recipe.model_dump())
    db.add(db_recipe)
    db.commit()
    db.refresh(db_recipe)
    return db_recipe

@router.get("/{recipe_id}", response_model=RecipeResponse)
def get_recipe(recipe_id: UUID, db: Session = Depends(get_db)):
    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return recipe

@router.delete("/{recipe_id}")
def delete_recipe(recipe_id: UUID, db: Session = Depends(get_db)):
    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    db.delete(recipe)
    db.commit()
    return {"message": f"Recipe {recipe_id} deleted successfully"}

@router.get("/", response_model=List[RecipeResponse])
def list_recipes(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    recipes = db.query(Recipe).offset(skip).limit(limit).all()
    return recipes

@router.get("/swipe/next", response_model=RecipeResponse)
def get_next_recipe_for_swiping(db: Session = Depends(get_db)):
    """
    Get the next recipe for the swipe interface.
    """
    logger.info("Fetching next recipe for swiping")
    
    # Get total count of recipes
    total_recipes = db.query(Recipe).count()
    logger.info(f"Total recipes in database: {total_recipes}")
    
    if total_recipes == 0:
        logger.warning("No recipes found in database")
        raise HTTPException(status_code=404, detail="No recipes available")
    
    # Get a random recipe
    random_offset = random.randint(0, total_recipes - 1)
    recipe = db.query(Recipe).offset(random_offset).limit(1).first()
    
    if recipe:
        logger.info(f"Found recipe: {recipe.title}")
        logger.info(f"Recipe has {len(recipe.images) if recipe.images else 0} images")
        return recipe
    else:
        logger.error("Failed to get random recipe")
        raise HTTPException(status_code=404, detail="No recipes available")