from sqlalchemy import Column, UUID, Integer, JSON, DateTime, ForeignKey
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class CookingSession(Base):
    __tablename__ = "cooking_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipe_id = Column(UUID(as_uuid=True), ForeignKey("recipes.id"), nullable=False)
    current_step = Column(Integer, default=0)  # 0-based index for step number
    conversation_history = Column(JSON, default=list)  # List of message objects
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())