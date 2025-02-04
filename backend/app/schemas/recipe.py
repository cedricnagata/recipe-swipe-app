from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID

class Recipe(BaseModel):
    id: UUID
    title: str
    ingredients: dict
    steps: List[str]
    source_url: Optional[str] = None
    images: List[Optional[str]] = []
    total_time: Optional[int] = None
    servings: Optional[int] = 4  # Default to 4 servings if not provided
    tags: List[str] = []
    hash: str
    is_saved: bool = False

    class Config:
        from_attributes = True