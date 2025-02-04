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

            # Extract servings
            servings = 0
            servings_text = response.css('.mm-recipes-details__item:contains("Servings") .mm-recipes-details__value::text').get()
            if servings_text:
                # Extract first number from the servings text
                servings_match = re.search(r'\d+', servings_text.strip())
                if servings_match:
                    servings = int(servings_match.group())
                    self.logger.info(f"Found servings: {servings}")
                else:
                    self.logger.warning(f"Could not parse servings number from: {servings_text}")
            else:
                self.logger.warning("No servings information found")

            # Extract ingredients with safer parsing
            ingredients = {}
            ingredient_elements = response.css('.mm-recipes-structured-ingredients__list-item')
            for element in ingredient_elements:
                # Safely get quantity, defaulting to empty string if None
                quantity = element.css('[data-ingredient-quantity]::text').get() or ''
                quantity = quantity.strip()
                
                # Safely get unit, defaulting to empty string if None
                unit = element.css('[data-ingredient-unit]::text').get() or ''
                unit = unit.strip()
                
                # Safely get name, defaulting to empty string if None
                name = element.css('[data-ingredient-name]::text').get() or ''
                name = name.strip()
                
                # Only add if we have a valid ingredient name
                if name:
                    full_amount = f"{quantity} {unit}".strip()
                    ingredients[name] = full_amount

            # Extract steps with safer parsing
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

            # Get recipe step images
            step_images = response.css('figure.mntl-sc-block-image img::attr(data-hi-res-src)').getall()
            step_images.reverse()  # Reverse to get final image first

            # Ensure we have exactly 5 image slots (fill with None if needed)
            while len(step_images) < 5:
                step_images.append(None)
            step_images = step_images[:5]  # Limit to 5 images

            # Create recipe data
            recipe_data = {
                'title': title,
                'servings': servings,
                'ingredients': ingredients,
                'steps': steps,
                'source_url': response.url,
                'images': step_images,
                'total_time': total_time,
                'tags': tags
            }

            # Generate hash for change detection
            content_hash = hashlib.sha256(
                json.dumps(recipe_data, sort_keys=True).encode()
            ).hexdigest()
            recipe_data['hash'] = content_hash

            # Skip if no ingredients or steps were found
            if not ingredients or not steps:
                self.logger.warning(f"Skipping recipe '{title}' due to missing ingredients or steps")
                return

            self.recipes_count += 1
            self.logger.info(f"Successfully scraped recipe {self.recipes_count}/{self.max_recipes}: {title}")
            yield recipe_data

            if self.recipes_count >= self.max_recipes:
                raise CloseSpider(f'Reached max recipes: {self.max_recipes}')

        except Exception as e:
            self.logger.error(f"Error scraping recipe from {response.url}: {str(e)}")
            raise e