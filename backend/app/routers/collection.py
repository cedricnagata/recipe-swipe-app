from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import Recipe
from app.services.scraper_service import ScraperService
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

class ScrapeRequest(BaseModel):
    max_recipes: int = 100  # Default to 100 if not specified

@router.post("/scrape-from-topics")
def scrape_from_topics(request: ScrapeRequest, db: Session = Depends(get_db)):
    """
    Scrape first recipe from each topic in AllRecipes A-Z listing
    """
    try:
        scraper = ScraperService(max_recipes=request.max_recipes)
        logger.info("Starting bulk scrape from topics")
        
        # Recipes will be processed and saved to the database as they're scraped
        results = scraper.bulk_scrape_from_topics(db)
        
        return {
            "message": f"Processed {len(results)} recipes",
            "results": [
                {
                    "url": recipe['source_url'],
                    "title": recipe['title'],
                    "status": "processed"
                } for recipe in results
            ]
        }
        
    except Exception as e:
        logger.error(f"Error in bulk scrape: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Error in bulk scrape: {str(e)}")