from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe
from app.services.recipe_scraper import RecipeScraper
from typing import List
from pydantic import BaseModel
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/collection",
    tags=["collection"]
)

class RecipeURL(BaseModel):
    url: str

@router.post("/scrape")
def scrape_recipe(recipe_url: RecipeURL, db: Session = Depends(get_db)):
    try:
        scraper = RecipeScraper()
        
        # Log the URL we're trying to scrape
        logger.info(f"Attempting to scrape URL: {recipe_url.url}")
        
        # Check if recipe already exists
        existing_recipe = db.query(Recipe).filter(Recipe.source_url == recipe_url.url).first()
        
        # Scrape the recipe
        recipe_data = scraper.scrape_recipe(recipe_url.url)
        
        # Log the scraped data
        logger.info(f"Scraped data: {recipe_data}")
        
        if not recipe_data:
            logger.error("Failed to scrape recipe - no data returned")
            raise HTTPException(status_code=400, detail="Failed to scrape recipe")
        
        if existing_recipe:
            # Update if hash differs
            if recipe_data['hash'] != existing_recipe.hash:
                logger.info(f"Updating existing recipe {existing_recipe.id}")
                for key, value in recipe_data.items():
                    setattr(existing_recipe, key, value)
                message = "Recipe updated successfully"
            else:
                message = "Recipe already exists and is up to date"
        else:
            # Create new recipe
            logger.info("Creating new recipe")
            db_recipe = Recipe(**recipe_data)
            db.add(db_recipe)
            message = "Recipe scraped successfully"
        
        db.commit()
        return {"message": message}
        
    except Exception as e:
        logger.error(f"Error in scrape_recipe: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error processing recipe: {str(e)}")

@router.post("/bulk-scrape")
def bulk_scrape_recipes(urls: List[RecipeURL], db: Session = Depends(get_db)):
    scraper = RecipeScraper()
    processed = []
    
    for url in urls:
        try:
            # Check if recipe exists
            existing_recipe = db.query(Recipe).filter(Recipe.source_url == url.url).first()
            
            # Scrape recipe
            recipe_data = scraper.scrape_recipe(url.url)
            
            if not recipe_data:
                processed.append({
                    "url": url.url,
                    "status": "failed",
                    "message": "Failed to scrape recipe"
                })
                continue
            
            if existing_recipe:
                if recipe_data['hash'] != existing_recipe.hash:
                    for key, value in recipe_data.items():
                        setattr(existing_recipe, key, value)
                    status = "updated"
                else:
                    status = "already up to date"
            else:
                db_recipe = Recipe(**recipe_data)
                db.add(db_recipe)
                status = "scraped"
                
            processed.append({
                "url": url.url,
                "status": status
            })
            
        except Exception as e:
            processed.append({
                "url": url.url,
                "status": "error",
                "message": str(e)
            })
    
    db.commit()
    return {"results": processed}