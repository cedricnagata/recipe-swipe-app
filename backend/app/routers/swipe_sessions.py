from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import event
from app.core.database import get_db
from app.models import Recipe, SavedRecipe, SwipeSession
from app.schemas.recipe import Recipe as RecipeSchema
from typing import Optional, List, Dict, Union
from uuid import UUID
import random
from sqlalchemy.orm.attributes import flag_modified
from pydantic import BaseModel

router = APIRouter(
    prefix="/swipe-sessions",
    tags=["swipe_sessions"]
)

LIKE_WEIGHT = 1.0
DISLIKE_WEIGHT = -0.5
DEFAULT_WEIGHT = 0.0

class NextRecipeResponse(BaseModel):
    has_more_recipes: bool
    recipe: Optional[RecipeSchema] = None

@router.post("/start")
async def start_session(db: Session = Depends(get_db)):
    """Start a new swiping session"""
    session = SwipeSession()
    session.seen_recipes = []
    db.add(session)
    db.commit()
    db.refresh(session)
    print(f"Created new session with ID: {session.id}")
    return {"session_id": session.id}

@router.post("/{session_id}/swipe/{recipe_id}")
async def register_swipe(
    session_id: UUID,
    recipe_id: UUID,
    liked: bool,
    save: bool = False,
    db: Session = Depends(get_db)
):
    """Register a swipe for a recipe and update tag weights"""
    print(f"\n--- Processing swipe for session {session_id} ---")
    
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Update seen recipes
    if session.seen_recipes is None:
        session.seen_recipes = []
    
    print(f"Current seen recipes: {session.seen_recipes}")
    
    if recipe_id not in session.seen_recipes:
        # Create a new list and assign it
        new_seen_recipes = list(session.seen_recipes)
        new_seen_recipes.append(recipe_id)
        session.seen_recipes = new_seen_recipes
        # Mark as modified
        flag_modified(session, "seen_recipes")
        print(f"Updated seen recipes to: {session.seen_recipes}")
    
    # Update tag weights
    if session.tag_weights is None:
        session.tag_weights = {}
    
    weight_change = LIKE_WEIGHT if liked else DISLIKE_WEIGHT
    for tag in recipe.tags:
        current_weight = session.tag_weights.get(tag, DEFAULT_WEIGHT)
        session.tag_weights[tag] = current_weight + weight_change
    
    # Mark tag_weights as modified too
    flag_modified(session, "tag_weights")
    
    # Save recipe if requested
    if save:
        existing_save = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
        if not existing_save:
            saved_recipe = SavedRecipe(recipe_id=recipe_id)
            db.add(saved_recipe)

    print("Committing changes...")
    db.commit()
    db.refresh(session)
    print(f"After commit - seen_recipes: {session.seen_recipes}")
    
    return {"message": "Swipe registered successfully"}

@router.get("/{session_id}/next", response_model=NextRecipeResponse)
async def get_next_recipe(session_id: UUID, db: Session = Depends(get_db)):
    """Get next recipe based on session preferences"""
    print(f"\n--- Getting next recipe for session {session_id} ---")
    
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    if session.seen_recipes is None:
        session.seen_recipes = []
        flag_modified(session, "seen_recipes")
        db.commit()

    # Get all recipes excluding seen ones
    total_recipes = db.query(Recipe).count()
    seen_recipe_ids = session.seen_recipes or []
    
    print(f"Total recipes: {total_recipes}")
    print(f"Seen recipes: {seen_recipe_ids}")
    
    unseen_recipes = db.query(Recipe).filter(Recipe.id.notin_(seen_recipe_ids)).all()
    print(f"Unseen recipes: {len(unseen_recipes)}")
    
    if not unseen_recipes:
        print("No more unseen recipes!")
        return NextRecipeResponse(has_more_recipes=False)

    # Calculate recipe scores
    tag_weights = session.tag_weights or {}
    recipe_scores = []
    
    for recipe in unseen_recipes:
        score = 0
        for tag in recipe.tags:
            weight = tag_weights.get(tag, DEFAULT_WEIGHT)
            score += weight
        recipe_scores.append((recipe, score))

    # Calculate probabilities
    total_score = sum(max(0.1, score) for _, score in recipe_scores)
    weights = [max(0.1, score) / total_score for _, score in recipe_scores]
    
    # Select recipe
    selected_recipe = random.choices(
        [recipe for recipe, _ in recipe_scores],
        weights=weights,
        k=1
    )[0]

    print(f"Selected recipe: {selected_recipe.id}")

    # Check if recipe is saved
    is_saved = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == selected_recipe.id).first() is not None

    # Create response with is_saved field
    recipe_dict = {
        "id": selected_recipe.id,
        "title": selected_recipe.title,
        "ingredients": selected_recipe.ingredients,
        "steps": selected_recipe.steps,
        "source_url": selected_recipe.source_url,
        "images": selected_recipe.images,
        "total_time": selected_recipe.total_time,
        "tags": selected_recipe.tags,
        "hash": selected_recipe.hash,
        "is_saved": is_saved
    }
    
    return NextRecipeResponse(has_more_recipes=True, recipe=recipe_dict)

@router.delete("/{session_id}")
async def end_session(session_id: UUID, db: Session = Depends(get_db)):
    """End a swiping session"""
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    print(f"Ending session {session_id}")
    print(f"Final seen_recipes: {session.seen_recipes}")
    
    db.delete(session)
    db.commit()
    return {"message": "Session ended successfully"}