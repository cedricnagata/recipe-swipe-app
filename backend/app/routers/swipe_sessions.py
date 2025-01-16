from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.models import Recipe, SavedRecipe, SwipeSession
from app.schemas.recipe import Recipe as RecipeSchema
from typing import Optional, List, Dict
from uuid import UUID
import random
import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/swipe-sessions",
    tags=["swipe_sessions"]
)

LIKE_WEIGHT = 1.0
DISLIKE_WEIGHT = -0.5
DEFAULT_WEIGHT = 0.0

@router.post("/start")
async def start_session(db: Session = Depends(get_db)):
    """Start a new swiping session"""
    session = SwipeSession()
    db.add(session)
    db.commit()
    db.refresh(session)
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
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Log before state
    logger.info(f"Before swipe - Tag weights: {session.tag_weights}")
    logger.info(f"Processing {'like' if liked else 'dislike'} for recipe: {recipe.title}")
    logger.info(f"Recipe tags: {recipe.tags}")

    # Update seen recipes
    seen_recipes = session.seen_recipes or []
    if recipe_id not in seen_recipes:
        seen_recipes.append(recipe_id)
        session.seen_recipes = seen_recipes

    # Update tag weights
    tag_weights = session.tag_weights or {}
    weight_change = LIKE_WEIGHT if liked else DISLIKE_WEIGHT
    
    for tag in recipe.tags:
        current_weight = tag_weights.get(tag, DEFAULT_WEIGHT)
        new_weight = current_weight + weight_change
        tag_weights[tag] = new_weight
        logger.info(f"Updated weight for tag '{tag}': {current_weight} -> {new_weight}")
    
    session.tag_weights = tag_weights
    
    # Save recipe if requested
    if save:
        existing_save = db.query(SavedRecipe).filter(SavedRecipe.recipe_id == recipe_id).first()
        if not existing_save:
            saved_recipe = SavedRecipe(recipe_id=recipe_id)
            db.add(saved_recipe)

    db.commit()
    return {
        "message": "Swipe registered successfully",
        "updated_weights": tag_weights
    }

def calculate_recipe_scores(recipes: List[Recipe], tag_weights: Dict[str, float]) -> List[tuple]:
    """Calculate scores for each recipe based on tag weights"""
    recipe_scores = []
    
    for recipe in recipes:
        score = 0
        tag_contributions = []
        for tag in recipe.tags:
            weight = tag_weights.get(tag, DEFAULT_WEIGHT)
            score += weight
            tag_contributions.append(f"{tag}: {weight}")
        
        recipe_scores.append((
            recipe,
            score,
            tag_contributions
        ))
        
    return recipe_scores

@router.get("/{session_id}/next", response_model=RecipeSchema)
async def get_next_recipe(session_id: UUID, db: Session = Depends(get_db)):
    """Get next recipe based on session preferences"""
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Get all recipes excluding seen ones
    seen_recipes = session.seen_recipes or []
    recipes = db.query(Recipe).filter(Recipe.id.notin_(seen_recipes)).all()
    
    if not recipes:
        raise HTTPException(status_code=404, detail="No more recipes available")

    # Calculate recipe scores and selection probabilities
    tag_weights = session.tag_weights or {}
    recipe_scores = calculate_recipe_scores(recipes, tag_weights)

    # Calculate probabilities
    total_score = sum(max(0.1, score) for _, score, _ in recipe_scores)
    if total_score <= 0:
        logger.info("All scores negative/zero, selecting random recipe")
        return random.choice(recipes)

    weights = [max(0.1, score) / total_score for _, score, _ in recipe_scores]
    
    # Log selection process
    logger.info("\nRecipe Selection Process:")
    for (recipe, score, tag_contributions), probability in zip(recipe_scores, weights):
        logger.info(f"\nRecipe: {recipe.title}")
        logger.info(f"Tags and their weights: {tag_contributions}")
        logger.info(f"Total Score: {score}")
        logger.info(f"Selection Probability: {probability * 100:.2f}%")

    # Select recipe
    selected_recipe = random.choices(
        [recipe for recipe, _, _ in recipe_scores],
        weights=weights,
        k=1
    )[0]

    logger.info(f"\nSelected Recipe: {selected_recipe.title}")
    return selected_recipe

@router.get("/{session_id}/debug")
async def debug_recipe_selection(session_id: UUID, db: Session = Depends(get_db)):
    """Debug endpoint to show recipe selection process"""
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Get available recipes
    seen_recipes = session.seen_recipes or []
    recipes = db.query(Recipe).filter(Recipe.id.notin_(seen_recipes)).all()
    
    if not recipes:
        return {"message": "No more recipes available"}

    # Calculate scores and probabilities
    tag_weights = session.tag_weights or {}
    recipe_scores = calculate_recipe_scores(recipes, tag_weights)
    
    total_score = sum(max(0.1, score) for _, score, _ in recipe_scores)
    weights = [max(0.1, score) / total_score for _, score, _ in recipe_scores]

    # Prepare detailed debug info
    debug_info = {
        "current_tag_weights": tag_weights,
        "seen_recipes_count": len(seen_recipes),
        "available_recipes_count": len(recipes),
        "recipe_analysis": [
            {
                "title": recipe.title,
                "tags": recipe.tags,
                "tag_contributions": tag_contributions,
                "total_score": score,
                "selection_probability": f"{(weight * 100):.2f}%"
            }
            for (recipe, score, tag_contributions), weight in zip(recipe_scores, weights)
        ]
    }

    return debug_info

@router.get("/{session_id}/stats")
async def get_session_stats(session_id: UUID, db: Session = Depends(get_db)):
    """Get session statistics"""
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    return {
        "tag_weights": session.tag_weights,
        "seen_recipes": len(session.seen_recipes or []),
        "created_at": session.created_at,
        "last_updated": session.last_updated
    }

@router.delete("/{session_id}")
async def end_session(session_id: UUID, db: Session = Depends(get_db)):
    """End a swiping session"""
    session = db.query(SwipeSession).filter(SwipeSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    db.delete(session)
    db.commit()
    return {"message": "Session ended successfully"}