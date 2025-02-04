from sqlalchemy import Column, String, JSON, Text, ARRAY, DateTime, UUID, Integer, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    ingredients = Column(JSON, nullable=False)
    steps = Column(ARRAY(Text), nullable=False)
    source_url = Column(String)
    images = Column(ARRAY(String), default=[])
    total_time = Column(Integer, nullable=True)  # in minutes
    servings = Column(Integer, nullable=True)    # number of servings
    tags = Column(ARRAY(String), default=[])
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    hash = Column(String(64))  # for change detection

class SavedRecipe(Base):
    __tablename__ = "saved_recipes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=False)
    saved_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<SavedRecipe(recipe_id={self.recipe_id})>"