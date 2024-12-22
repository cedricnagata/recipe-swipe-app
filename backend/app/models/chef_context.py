from sqlalchemy import Column, String, JSON, DateTime, UUID, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class ChefContext(Base):
    __tablename__ = "chef_contexts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_preferences_id = Column(UUID(as_uuid=True), ForeignKey('user_preferences.id'), nullable=False)
    current_recipe_id = Column(UUID(as_uuid=True), ForeignKey('recipes.id'), nullable=True)
    current_step = Column(JSON, nullable=True)  # Current step details and progress
    session_data = Column(JSON, default={})  # Store any session-specific data
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user_preferences = relationship("UserPreferences")
    current_recipe = relationship("Recipe")