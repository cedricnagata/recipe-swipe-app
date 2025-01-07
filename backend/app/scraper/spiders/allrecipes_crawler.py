import scrapy
from urllib.parse import urlparse
import hashlib
import json
from scrapy.exceptions import CloseSpider
import re

def parse_time_to_minutes(time_str: str) -> int:
    """Convert time string like '1 hr 25 mins' to minutes"""
    if not time_str:
        return 0
        
    total_minutes = 0
    # Find hours
    hr_match = re.search(r'(\d+)\s*hr', time_str)
    if hr_match:
        total_minutes += int(hr_match.group(1)) * 60
    
    # Find minutes
    min_match = re.search(r'(\d+)\s*mins', time_str)
    if min_match:
        total_minutes += int(min_match.group(1))
        
    return total_minutes

class AllrecipesCrawlerSpider(scrapy.Spider):
    name = 'allrecipes_crawler'
    allowed_domains = ['allrecipes.com']
    start_urls = ['https://www.allrecipes.com/recipes-a-z-6735880']
    
    custom_settings = {
        'ROBOTSTXT_OBEY': False,
        'DOWNLOAD_DELAY': 2,
        'USER_AGENT': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'ITEM_PIPELINES': {
            'app.scraper.pipelines.DatabasePipeline': 300,
        }
    }

    def __init__(self, db_session=None, max_recipes=100, *args, **kwargs):
        super(AllrecipesCrawlerSpider, self).__init__(*args, **kwargs)
        self.recipes_count = 0
        self.max_recipes = max_recipes
        self.db_session = db_session

    def parse(self, response):
        if self.recipes_count >= self.max_recipes:
            raise CloseSpider(f'Reached max recipes: {self.max_recipes}')
            
        topic_links = response.css('.mntl-link-list__link::attr(href)').getall()
        self.logger.info(f"Found {len(topic_links)} topic links")
        
        for link in topic_links:
            if self.recipes_count >= self.max_recipes:
                raise CloseSpider(f'Reached max recipes: {self.max_recipes}')
            yield scrapy.Request(
                url=link,
                callback=self.parse_topic_page,
                meta={'topic_url': link}
            )

    def parse_topic_page(self, response):
        if self.recipes_count >= self.max_recipes:
            raise CloseSpider(f'Reached max recipes: {self.max_recipes}')

        first_recipe_link = response.css('.mntl-card-list-items[href*="/recipe/"]::attr(href)').get()
        topic_url = response.meta['topic_url']
        
        if first_recipe_link:
            self.logger.info(f"Found recipe in topic {topic_url}: {first_recipe_link}")
            yield scrapy.Request(
                url=first_recipe_link,
                callback=self.parse_recipe,
                meta={'topic_url': topic_url},
                dont_filter=True
            )
        else:
            self.logger.warning(f"No recipe found in topic: {topic_url}")

    def parse_recipe(self, response):
        if self.recipes_count >= self.max_recipes:
            raise CloseSpider(f'Reached max recipes: {self.max_recipes}')

        try:
            # Extract title
            title = response.css('title::text').get().strip().replace(' Recipe', '')

            # Extract ingredients
            ingredients = {}
            ingredient_elements = response.css('.mm-recipes-structured-ingredients__list-item')
            for element in ingredient_elements:
                quantity = element.css('[data-ingredient-quantity]::text').get().strip()
                unit = element.css('[data-ingredient-unit]::text').get()
                unit = unit.strip() if unit else ''
                name = element.css('[data-ingredient-name]::text').get().strip()
                
                if name:
                    full_amount = f"{quantity} {unit}".strip()
                    ingredients[name] = full_amount

            # Extract steps
            steps = []
            step_elements = response.css('.mm-recipes-steps__content .mntl-sc-block-group--OL .mntl-sc-block-html')
            for step in step_elements:
                step_text = step.css('p::text').get()
                if step_text:
                    steps.append(step_text.strip())

            # Extract total time
            total_time = 0
            total_time_element = response.css('.mm-recipes-details__item:contains("Total Time") .mm-recipes-details__value::text').get()
            if total_time_element:
                total_time = parse_time_to_minutes(total_time_element.strip())

            # Extract parsely tags
            tags = response.css('meta[name="parsely-tags"]::attr(content)').get()
            tags = [tag.strip() for tag in tags.split(',')] if tags else []

            # Extract images
            images = []
            seen_images = set()
            ribbon_images = response.css('#article__photo-ribbon_1-0 img::attr(data-src)').getall()
            
            for img_url in ribbon_images:
                if img_url:
                    normalized_url = urlparse(img_url).path
                    if normalized_url not in seen_images:
                        seen_images.add(normalized_url)
                        images.append(img_url)
                        
                    if len(images) >= 5:
                        break

            while len(images) < 5:
                images.append(None)

            # Create recipe data
            recipe_data = {
                'title': title,
                'ingredients': ingredients,
                'steps': steps,
                'source_url': response.url,
                'images': images,
                'total_time': total_time,
                'tags': tags
            }

            # Generate hash for change detection
            content_hash = hashlib.sha256(
                json.dumps(recipe_data, sort_keys=True).encode()
            ).hexdigest()
            recipe_data['hash'] = content_hash

            self.recipes_count += 1
            self.logger.info(f"Successfully scraped recipe {self.recipes_count}/{self.max_recipes}: {title}")
            yield recipe_data

            if self.recipes_count >= self.max_recipes:
                raise CloseSpider(f'Reached max recipes: {self.max_recipes}')

        except Exception as e:
            self.logger.error(f"Error scraping recipe from {response.url}: {str(e)}")
            raise e