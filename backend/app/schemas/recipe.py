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
    tags: List[str] = []
    hash: str
    is_saved: bool = False

    class Config:
        from_attributes = True