CLHousingSearch
===============

A web scraper for harvesting Craigslist housing posts.

I wrote this to help myself search for housing. At the time, this solved the
problem of analyzing all posts at once, rather than page by page. Since it was
all automatable, I could very quickly and easily update the database and sort
posts by my criteria instead of browsing the site manually and taking notes.

Most of the parsing looks to be broken by now, and anyway Craigslist has since
added features that make it somewhat more usable.

CLHousingSearch is the main module implementing the scraping. The test script
uses CLHousingSearch to dump the scraped content for debugging, and the
harvest script uses CLHousingSearch to import all the posts into a SQL
database with columns for URL, rent, bedrooms, neightborhood, and description.
