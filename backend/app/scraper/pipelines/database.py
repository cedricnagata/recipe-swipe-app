from app.models import Recipe
import logging

logger = logging.getLogger(__name__)

class DatabasePipeline:
    def __init__(self, db_session):
        self.db_session = db_session

    @classmethod
    def from_crawler(cls, crawler):
        return cls(
            db_session=crawler.spider.db_session
        )

    def process_item(self, item, spider):
        try:
            # Check if recipe exists
            existing_recipe = self.db_session.query(Recipe).filter(
                Recipe.source_url == item['source_url']
            ).first()

            if existing_recipe:
                if item['hash'] != existing_recipe.hash:
                    # Update existing recipe
                    for key, value in item.items():
                        setattr(existing_recipe, key, value)
                    logger.info(f"Updated recipe: {item['title']}")
            else:
                # Create new recipe
                db_recipe = Recipe(**item)
                self.db_session.add(db_recipe)
                logger.info(f"Added new recipe: {item['title']}")

            # Commit after each recipe
            self.db_session.commit()
            return item

        except Exception as e:
            logger.error(f"Error processing recipe {item.get('title', 'Unknown')}: {str(e)}")
            self.db_session.rollback()
            raise