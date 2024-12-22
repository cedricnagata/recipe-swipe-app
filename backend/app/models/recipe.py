from sqlalchemy import Column, String, JSON, Text, ARRAY, DateTime, UUID
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
    image_url = Column(String)  # Main recipe image
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    hash = Column(String(64))  # for change detection