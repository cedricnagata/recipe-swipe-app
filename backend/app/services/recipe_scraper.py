import requests
from bs4 import BeautifulSoup
import hashlib
import json
from typing import Dict, List, Optional

class AllRecipesScraper:
    def __init__(self):
        self.base_url = "https://www.allrecipes.com"
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

    def get_recipe_data(self, url: str) -> Optional[Dict]:
        """
        Scrapes recipe data from an AllRecipes URL
        Returns None if scraping fails
        """
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')

            # Get recipe title
            title = soup.find('h1', class_='article-heading').text.strip()

            # Get ingredients
            ingredients_list = soup.find_all('li', class_='ingredients-item')
            ingredients = {}
            for item in ingredients_list:
                ingredient_text = item.text.strip()
                # Split quantity and ingredient name (basic implementation)
                parts = ingredient_text.split(' ', 1)
                if len(parts) == 2:
                    quantity, name = parts
                    ingredients[name.strip()] = quantity.strip()
                else:
                    ingredients[ingredient_text] = "to taste"

            # Get steps
            steps_list = soup.find_all('li', class_='instructions-section-item')
            steps = [step.text.strip() for step in steps_list]

            # Get main image
            image_container = soup.find('div', class_='article-content')
            image_url = None
            if image_container:
                image_element = image_container.find('img')
                if image_element and 'src' in image_element.attrs:
                    image_url = image_element['src']

            # Generate hash for change detection
            content_hash = hashlib.sha256(
                json.dumps({
                    'title': title,
                    'ingredients': ingredients,
                    'steps': steps,
                    'image_url': image_url
                }, sort_keys=True).encode()
            ).hexdigest()

            return {
                'title': title,
                'ingredients': ingredients,
                'steps': steps,
                'source_url': url,
                'image_url': image_url,
                'hash': content_hash
            }

        except Exception as e:
            print(f"Error scraping recipe from {url}: {str(e)}")
            return None

    def is_recipe_updated(self, url: str, old_hash: str) -> bool:
        """
        Checks if a recipe has been updated by comparing hashes
        """
        recipe_data = self.get_recipe_data(url)
        if recipe_data is None:
            return False
        return recipe_data['hash'] != old_hash