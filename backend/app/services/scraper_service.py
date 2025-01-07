from scrapy.crawler import CrawlerRunner
from scrapy.utils.project import get_project_settings
from app.scraper.spiders.allrecipes_crawler import AllrecipesCrawlerSpider
from twisted.internet import reactor
from scrapy.utils.log import configure_logging
from typing import List, Dict, Any
import os
from scrapy import signals
from twisted.internet.defer import Deferred
from crochet import setup, wait_for
from scrapy.signalmanager import dispatcher

# Initialize crochet
setup()

class ScraperService:
    def __init__(self, max_recipes):
        configure_logging()
        os.environ['SCRAPY_SETTINGS_MODULE'] = 'app.scraper.settings.settings'
        self.runner = CrawlerRunner(get_project_settings())
        self.max_recipes = max_recipes
        self.items = []

    def _item_scraped(self, item, response, spider):
        """Callback function that's called when an item is scraped"""
        self.items.append(item)

    @wait_for(timeout=1800)  # 30 minutes timeout (increased from 5 minutes)
    def bulk_scrape_from_topics(self, db_session) -> List[Dict[str, Any]]:
        """Scrape the first recipe from each topic in the A-Z listing"""
        # Clear any previous items
        self.items = []
        
        # Connect the item scraped signal
        dispatcher.connect(self._item_scraped, signal=signals.item_scraped)
        
        # Start the crawl with the database session
        d = self.runner.crawl(AllrecipesCrawlerSpider, db_session=db_session, max_recipes=self.max_recipes)
        
        # Return the items after the crawl is done
        return d.addCallback(lambda _: self.items)