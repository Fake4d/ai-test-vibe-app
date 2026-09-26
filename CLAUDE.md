# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A collection of standalone single-file HTML apps for vibe coding experiments. No build system, no dependencies, no package manager — each file is self-contained and opens directly in a browser.

`tools/` holds small standalone helper scripts (e.g. `tools/codex-update/`), each with its own README.

## Design conventions

- Dark theme with CSS custom properties (`--bg`, `--surface`, `--accent`, etc.) in rss-reader; light card-on-grey in plz-suche.
- rss-reader renders all feed content via DOM APIs (`textContent`, never `innerHTML`) and passes links through `sanitizeUrl()` — keep it that way (hardened against XSS in 68ea53e). plz-suche uses `escapeHtml()` for user-controlled and API data.
