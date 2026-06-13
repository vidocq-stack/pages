# AGENTS.md

This file defines repository rules for humans and coding agents working on this website.

## Project Purpose

- This repository hosts a website built with **Roq**.
- Keep the site easy to maintain, easy to evolve, and friendly to contributors.

## Core Rules

1. **Use AsciiDoc first**
   - Write and maintain content in AsciiDoc (`.adoc`) whenever possible.
   - Avoid adding raw HTML for content pages unless there is no equivalent AsciiDoc solution.
   - If HTML is unavoidable, keep it minimal and document why.
   - index.html is the only exception: it is a static landing page with no AsciiDoc equivalent.

2. **Responsive by default**
   - Every UI change must work on mobile, tablet, and desktop.
   - Prefer fluid layouts, relative units, and accessible spacing.
   - Validate common breakpoints before finalizing changes.

3. **Modern and simple UI**
   - Keep the visual style modern, clean, and minimal.
   - Prioritize readability, hierarchy, and fast loading.
   - Avoid visual clutter, excessive animations, or heavy components.

4. **Highly customizable structure**
   - Favor reusable templates, variables, and theme-level overrides.
   - Avoid hardcoded styles/content when configurable alternatives exist.
   - Keep customization points explicit and documented.

5. **English content only**
   - All user-facing content must be written in English.
   - Keep wording clear, concise, and consistent in tone.

## Content and Layout Guidelines

- Prefer editing content under `content/` in AsciiDoc.
- Keep structural/template logic in theme/layout files, not in content pages.
- Use CSS customizations in a maintainable way (small, scoped, and documented changes).

## Pull Request Checklist

Before submitting a change, verify:

- [ ] Content is in English.
- [ ] Content uses AsciiDoc (or includes a clear reason for necessary HTML).
- [ ] UI remains responsive on mobile, tablet, and desktop.
- [ ] Design stays modern, simple, and readable.
- [ ] Customization remains easy (no unnecessary hardcoding).
- [ ] New rules/decisions are documented when relevant.

