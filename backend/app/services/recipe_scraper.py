import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse
import hashlib
import json
from typing import Dict, List, Optional

class RecipeScraper:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }

    def normalize_image_url(self, url: str) -> str:
        """Normalize the image URL by removing query parameters"""
        parsed = urlparse(url)
        return parsed.path

    def scrape_recipe(self, url: str) -> Optional[Dict]:
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')

            # Extract title
            title = soup.find('title').text.strip().replace(' Recipe', '')

            # Extract ingredients
            ingredients = {}
            ingredient_elements = soup.find_all('li', class_='mm-recipes-structured-ingredients__list-item')
            for element in ingredient_elements:
                quantity = element.find('span', attrs={'data-ingredient-quantity': 'true'}).text.strip()
                unit = element.find('span', attrs={'data-ingredient-unit': 'true'})
                unit = unit.text.strip() if unit else ''
                name = element.find('span', attrs={'data-ingredient-name': 'true'}).text.strip()
                
                if name:
                    full_amount = f"{quantity} {unit}".strip()
                    ingredients[name] = full_amount

            # Extract steps
            steps = []
            steps_div = soup.find('div', class_='mm-recipes-steps__content')
            if steps_div:
                steps_elements = steps_div.find_all('p', class_='mntl-sc-block-html')
                steps = [step.text.strip() for step in steps_elements if step.text.strip()]

            # Extract unique images from the photo ribbon
            images = []
            seen_images = set()
            ribbon = soup.find(id='article__photo-ribbon_1-0')
            if ribbon:
                img_elements = ribbon.find_all('img')
                for img in img_elements:
                    src = img.get('data-src') or img.get('src')
                    if src:
                        normalized_src = self.normalize_image_url(src)
                        if normalized_src not in seen_images:
                            seen_images.add(normalized_src)
                            images.append(src)
                            if len(images) >= 5:
                                break

            # Fill remaining image slots with None if needed
            while len(images) < 5:
                images.append(None)

            # Validate required fields
            if not title or not ingredients or not steps:
                return None

            # Create recipe data
            recipe_data = {
                'title': title,
                'ingredients': ingredients,
                'steps': steps,
                'source_url': url,
                'images': images
            }

            # Generate hash for change detection
            content_hash = hashlib.sha256(
                json.dumps(recipe_data, sort_keys=True).encode()
            ).hexdigest()
            recipe_data['hash'] = content_hash

            return recipe_data

        except Exception as e:
            print(f"Error scraping recipe from {url}: {str(e)}")
            return None