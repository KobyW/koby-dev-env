#!/usr/bin/env python3
"""Firecrawl scrape script - scrapes URLs and returns markdown content."""

import argparse
import json
import os
import sys

from firecrawl import FirecrawlApp


def load_api_key() -> str:
    """Load FIRECRAWL_API_KEY from environment or .claude/.env."""
    key = os.environ.get("FIRECRAWL_API_KEY")
    if key:
        return key

    env_path = os.path.expanduser("~/.claude/.env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("FIRECRAWL_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")

    print("Error: FIRECRAWL_API_KEY not found in environment or ~/.claude/.env", file=sys.stderr)
    sys.exit(1)


def scrape_url(url: str, fmt: str = "markdown") -> str:
    """Scrape a single URL and return content."""
    app = FirecrawlApp(api_key=load_api_key())

    formats = [fmt]
    if fmt == "markdown":
        formats = ["markdown"]
    elif fmt == "html":
        formats = ["html"]
    else:
        formats = ["markdown"]

    result = app.scrape(url, formats=formats)

    if hasattr(result, "markdown") and result.markdown:
        return result.markdown
    if hasattr(result, "html") and result.html:
        return result.html
    return json.dumps(result if isinstance(result, dict) else vars(result), indent=2, default=str)


def search_and_scrape(query: str) -> str:
    """Search the web and return results."""
    app = FirecrawlApp(api_key=load_api_key())
    results = app.search(query, limit=5)

    items = results if isinstance(results, list) else getattr(results, "data", [])
    output_parts = []
    for item in items:
        if isinstance(item, dict):
            title = item.get("title", "Untitled")
            url = item.get("url", "")
            markdown = item.get("markdown", item.get("description", ""))
        else:
            title = getattr(item, "title", "Untitled")
            url = getattr(item, "url", "")
            markdown = getattr(item, "markdown", getattr(item, "description", ""))
        output_parts.append(f"## {title}\n**URL:** {url}\n\n{markdown}")

    return "\n\n---\n\n".join(output_parts) if output_parts else "No results found."


def main():
    parser = argparse.ArgumentParser(description="Scrape web pages via Firecrawl")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--url", help="URL to scrape")
    group.add_argument("--search", help="Search query")
    parser.add_argument("--format", default="markdown", choices=["markdown", "html", "text"],
                        help="Output format (default: markdown)")
    args = parser.parse_args()

    if args.url:
        content = scrape_url(args.url, args.format)
    else:
        content = search_and_scrape(args.search)

    print(content)


if __name__ == "__main__":
    main()
