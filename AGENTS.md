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

6. **Terminology: "Java Modules", never "JPMS"**
   - Write **Java Modules** for the platform module system, and **a Java module** for a single one.
   - Never use the abbreviation *JPMS* — not in prose, not in headings, not in identifiers.
   - Phrasings already established across the ecosystem: `Java Modules-native`,
     `Strict Java Modules`, `a proper Java module`.
   - Watch for wording that becomes redundant after the swap: *"Strict JPMS module isolation"*
     must become *"Strict Java Modules isolation"*, not *"Java Modules module isolation"*.
   - **One exception**: text that quotes tool output verbatim (build logs, error messages,
     compiler warnings). The quote must keep matching what the tool actually prints. Change the
     tool first, then the quote — never the other way round.
   - This is an ecosystem-wide convention, not a rule local to this site.

## Content and Layout Guidelines

- Prefer editing content under `content/` in AsciiDoc.
- Keep structural/template logic in theme/layout files, not in content pages.
- Use CSS customizations in a maintainable way (small, scoped, and documented changes).
- **A post's published URL comes from its `title:`, not its filename.** Roq slugifies the title:
  `content/posts/2026-07-16-multi-module-jpms-apps-on-vidocq.adoc` is published at
  `/posts/multi-module-jpms-apps-on-vidocq-one-opens-one-split-package-and-a-fix/`. So:
  - **Renaming a post file is free** — the URL does not follow it.
  - **Retitling a published post is a breaking change.** Raise it first and pair it with a
    redirect. The title also appears on the home page, the blog index, the author pages and the
    prev/next links of neighbouring posts, so it is never a one-page edit.
- Standalone pages pin their path with a `link:` key (e.g. `link: /contributing/`), so both their
  filename and their title are free to change.
- AsciiDoc section headings generate the `#anchor` that deep links rely on. Default Asciidoctor
  id rules apply here — `== What this episode says` becomes `#_what_this_episode_says`, with a
  leading underscore and underscores as separators.
- **Verify against a real build before trusting any of the above.** Absence of a `slug:` or
  `permalink:` key does *not* imply filename-derived URLs — that assumption was wrong once
  already. Build and inspect `target/roq/`:

  ```
  ./mvnw package -ntp -DskipTests -Dquarkus.roq.generator.batch=true
  java -jar target/quarkus-app/quarkus-run.jar
  ```

## Pull Request Checklist

Before submitting a change, verify:

- [ ] Content is in English.
- [ ] Terminology says "Java Modules", never "JPMS" (except in verbatim tool output).
- [ ] No published post retitled and no anchor renamed without a heads-up and a redirect
      (a post's URL follows its `title:`).
- [ ] Content uses AsciiDoc (or includes a clear reason for necessary HTML).
- [ ] UI remains responsive on mobile, tablet, and desktop.
- [ ] Design stays modern, simple, and readable.
- [ ] Customization remains easy (no unnecessary hardcoding).
- [ ] New rules/decisions are documented when relevant.

