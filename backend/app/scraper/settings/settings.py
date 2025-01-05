BOT_NAME = 'allrecipes_scraper'

SPIDER_MODULES = ['app.scraper.spiders']
NEWSPIDER_MODULE = 'app.scraper.spiders'

# Crawl responsibly by identifying yourself
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

# Obey robots.txt rules
ROBOTSTXT_OBEY = False

# Configure maximum concurrent requests
CONCURRENT_REQUESTS = 1
CONCURRENT_REQUESTS_PER_DOMAIN = 1

# Configure a delay for requests
DOWNLOAD_DELAY = 2

# Disable cookies
COOKIES_ENABLED = False

# Configure default headers
DEFAULT_REQUEST_HEADERS = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en',
}