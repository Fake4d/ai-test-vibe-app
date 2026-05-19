# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A collection of standalone single-file HTML apps for vibe coding experiments. No build system, no dependencies, no package manager — each file is self-contained and opens directly in a browser.

## Running the apps

Open any `.html` file directly in a browser, or serve locally to avoid some CORS issues:

```bash
python3 -m http.server 8080
```

## Architecture

Each app is a single HTML file containing inline CSS (`<style>`) and inline JavaScript (`<script>`). There is no bundler, no framework, and no external dependencies loaded via npm.

**Files:**
- `rss-reader.html` — RSS/Atom feed reader. Fetches feeds via a CORS proxy cascade (allorigins `/get` → allorigins `/raw` → direct fetch), parses XML with `DOMParser`, and renders article cards with a modal overlay. Supports RSS 2.0 and Atom, extracts images from `media:content`, `media:thumbnail`, `enclosure`, and CDATA `<img>` tags. UI language is German.
- `plz-suche.html` — German postal code lookup. Queries `api.zippopotam.us/de/{plz}` and displays city/state. UI language is German.

## External APIs

| App | API | Purpose |
|-----|-----|---------|
| rss-reader | `https://api.allorigins.win` | CORS proxy for RSS feeds |
| plz-suche | `https://api.zippopotam.us/de/{plz}` | Postal code → city/state |

## Design conventions

- Dark theme with CSS custom properties (`--bg`, `--surface`, `--accent`, etc.) in rss-reader; light card-on-grey in plz-suche.
- No XSS escaping of RSS content in rss-reader (intentional — feed content is injected as HTML for rich descriptions); plz-suche uses `escapeHtml()` for user-controlled and API data.
