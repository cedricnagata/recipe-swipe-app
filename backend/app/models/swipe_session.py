from sqlalchemy import Column, UUID, JSON, ARRAY, DateTime
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class SwipeSession(Base):
    __tablename__ = "swipe_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tag_weights = Column(JSON, default={})  # Store tag weights: {"tag": weight}
    seen_recipes = Column(ARRAY(UUID(as_uuid=True)), default=[])  # Keep as UUID array
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())