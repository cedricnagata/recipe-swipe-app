from sqlalchemy import Column, String, JSON, ARRAY, UUID
from app.core.database import Base
import uuid

class UserPreferences(Base):
    __tablename__ = "user_preferences"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dietary_restrictions = Column(ARRAY(String), default=[])
    cooking_skill_level = Column(String, nullable=False)  # beginner, intermediate, advanced
    kitchen_equipment = Column(JSON, default={})  # Dict of equipment and their availability
    favorite_cuisines = Column(ARRAY(String), default=[])