from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe
from app.services.recipe_scraper import AllRecipesScraper
from typing import List
from pydantic import BaseModel, HttpUrl

router = APIRouter(
    prefix="/collection",
    tags=["collection"]
)

class RecipeURL(BaseModel):
    url: str

@router.post("/scrape")
async def scrape_recipe(
    recipe_url: RecipeURL,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    scraper = AllRecipesScraper()
    
    # Check if recipe already exists
    existing_recipe = db.query(Recipe).filter(Recipe.source_url == recipe_url.url).first()
    
    if existing_recipe:
        # Check if recipe needs updating
        if not scraper.is_recipe_updated(recipe_url.url, existing_recipe.hash):
            return {"message": "Recipe already exists and is up to date"}
    
    # Scrape the recipe
    recipe_data = scraper.get_recipe_data(recipe_url.url)
    if not recipe_data:
        raise HTTPException(status_code=400, detail="Failed to scrape recipe")
    
    if existing_recipe:
        # Update existing recipe
        for key, value in recipe_data.items():
            setattr(existing_recipe, key, value)
        message = "Recipe updated successfully"
    else:
        # Create new recipe
        db_recipe = Recipe(**recipe_data)
        db.add(db_recipe)
        message = "Recipe scraped successfully"
    
    db.commit()
    return {"message": message}

@router.post("/bulk-scrape")
async def bulk_scrape_recipes(
    urls: List[RecipeURL],
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Bulk scrape recipes from multiple URLs
    """
    results = []
    for recipe_url in urls:
        try:
            scraper = AllRecipesScraper()
            recipe_data = scraper.get_recipe_data(recipe_url.url)
            
            if recipe_data:
                existing_recipe = db.query(Recipe).filter(
                    Recipe.source_url == recipe_url.url
                ).first()
                
                if existing_recipe:
                    if scraper.is_recipe_updated(recipe_url.url, existing_recipe.hash):
                        for key, value in recipe_data.items():
                            setattr(existing_recipe, key, value)
                        results.append({
                            "url": recipe_url.url,
                            "status": "updated"
                        })
                    else:
                        results.append({
                            "url": recipe_url.url,
                            "status": "already up to date"
                        })
                else:
                    db_recipe = Recipe(**recipe_data)
                    db.add(db_recipe)
                    results.append({
                        "url": recipe_url.url,
                        "status": "scraped"
                    })
            else:
                results.append({
                    "url": recipe_url.url,
                    "status": "failed"
                })
                
        except Exception as e:
            results.append({
                "url": recipe_url.url,
                "status": "error",
                "message": str(e)
            })
    
    db.commit()
    return {"results": results}