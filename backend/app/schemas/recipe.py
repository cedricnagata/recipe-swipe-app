from pydantic import BaseModel
from typing import List, Optional, Dict
from uuid import UUID

class RecipeBase(BaseModel):
    title: str
    ingredients: Dict[str, str]
    steps: List[str]
    source_url: Optional[str] = None
    images: List[Optional[str]] = []
    total_time: Optional[int] = None
    tags: List[str] = []

class RecipeCreate(RecipeBase):
    pass

class Recipe(RecipeBase):
    id: UUID
    hash: Optional[str] = None

    class Config:
        from_attributes = True

class SavedRecipeResponse(BaseModel):
    recipe_id: UUID
    saved_at: str

    class Config:
        from_attributes = True