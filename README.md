# Vidocq Site

Official website for the Vidocq ecosystem, built with **Quarkus + Roq**.

The site serves both a project presentation and a technical blog.
Content is written in **AsciiDoc**, stored under version control, and published as a static site at **https://vidocq.dev**.

## Structure

```
content/
  index.html                    # Landing page
  projects.adoc                 # All fifteen Vidocq sub-projects
  contributing.adoc             # Contribution guide
  blog.adoc                     # Blog index
  posts/                        # Blog articles (one .adoc file per post)
data/
  menu.yml                      # Navigation items
  authors.yml                   # Author metadata
public/
  images/                       # Static images (logo, banners, …)
templates/
  theme-layouts/roq-default/    # Overridden Roq theme layouts
  tags/roq/                     # Overridden Qute user tags
web/
  _custom.css                   # Custom Tailwind / CSS overrides
src/main/resources/
  application.properties        # Roq and Quarkus configuration
.woodpecker.yaml                # CI/CD pipeline (Codeberg Woodpecker)
```

## Prerequisites

- **Java 21** (Temurin) + **Maven 3.9** — or use `./mvnw` which downloads Maven automatically.

## Run locally

```bash
./mvnw quarkus:dev
```

Open http://localhost:8080. Changes to content, CSS, and templates are picked up live.

## Build and generate the static site

```bash
# 1. Compile and package
mvn package -ntp -DskipTests

# 2. Run the generator (outputs to target/roq/)
java -Dquarkus.roq.generator.batch=true -jar target/quarkus-app/quarkus-run.jar
```

The complete static site is written to **`target/roq/`**. Open `target/roq/index.html` in a browser to verify before publishing.

## Writing a blog post

1. Add a new `.adoc` file in `content/posts/` — name it `YYYY-MM-DD-slug.adoc`.
2. Open with front matter:

   ```
   ---
   title: Your Post Title
   description: One-line summary.
   date: YYYY-MM-DD
   layout: post
   author: vidocq-team
   tags: [tag1, tag2]
   ---
   ```

3. Write content in AsciiDoc below the front matter.
4. Open a PR against `main`. The site is rebuilt and redeployed automatically on merge.

## Adding a page

1. Add a `.adoc` file in `content/` (e.g., `content/roadmap.adoc`).
2. Front matter must include `layout: page` and `link: /roadmap/`.
3. Add the page to `data/menu.yml` if it should appear in the top navigation.

---

## Deployment — Codeberg Pages + Forgejo Actions

### Repository layout (Codeberg Pages requirement)

Codeberg Pages for the `Vidocq` organisation is served from a **dedicated repository named `pages`**
(`codeberg.org/Vidocq/pages`) on a branch also named **`pages`**.

This repository (`pages`) holds the source.
The CI workflow builds the static site here and pushes the output to `Vidocq/pages@pages`.

```
codeberg.org/Vidocq/pages   ← source (this repo, branch: main)
codeberg.org/Vidocq/pages          ← generated output (branch: pages)  →  vidocq.codeberg.page
```

### How it works

Every push to `main` triggers the Forgejo Actions workflow
(`.forgejo/workflows/deploy-pages.yaml`) that:

1. **Builds** the Quarkus Roq app with Maven (Java 21 container).
2. **Generates** the complete static site into `target/roq/` via Roq's batch generator.
3. **Pushes** the generated files to `Vidocq/pages` on the `pages` branch.
4. Writes a `.domains` file so Codeberg Pages serves the site at `vidocq.dev`.

### First-time setup

#### 1. Create the `Vidocq/pages` repository on Codeberg

Create a new **empty** repository named exactly `pages` under the `Vidocq` organisation.
No README, no `.gitignore` — the CI will push the first commit.

#### 2. Enable Forgejo Actions on both repositories

In Codeberg, Forgejo Actions must be enabled per-repository:

- `Vidocq/pages` → **Settings → Actions → Enable**
- `Vidocq/pages` → **Settings → Actions → Enable** (not strictly required, but consistent)

#### 3. Add the deploy secret

The workflow pushes to `Vidocq/pages` using a personal access token.

1. In Codeberg, go to **User Settings → Applications → Access Tokens**.
2. Generate a token with scope **`repository`** (read + write). Name it `ci-deploy-pages`.
3. In `Vidocq/pages`, go to **Settings → Actions → Secrets**.
4. Create a secret named **`CODEBERG_TOKEN`** and paste the token value.

#### 4. Configure your runners

The workflow uses `runs-on: ubuntu-latest`.
Your self-hosted `act_runner` instances must be registered with that label (the Forgejo runner default).

The workflow uses `actions/cache` for the Maven local repository.
Make sure the cache service is enabled in your Forgejo instance
(`[actions] ENABLED = true` and `[cache] ENABLED = true` in `app.ini`).

#### 5. Configure DNS for vidocq.dev

Add the following DNS records at your registrar:

| Type  | Name       | Value                  | TTL |
|-------|------------|------------------------|-----|
| CNAME | `www`      | `vidocq.codeberg.page` | 300 |
| CNAME | `@` (apex) | `vidocq.codeberg.page` | 300 |

> Apex CNAME requires CNAME-flattening (Cloudflare, Porkbun) or an `ALIAS`/`ANAME` record.
> Cloudflare with the proxy enabled handles this transparently.

#### 6. Trigger the first deployment

Push any commit to `main` (or run the workflow manually from the Actions tab).
The pipeline creates the `pages` branch in `Vidocq/pages` on its first run.

After the push, Codeberg Pages picks up the `.domains` file within a few minutes and starts
serving the custom domain.

#### 7. Verify

```
https://vidocq.dev          ← live site
https://vidocq.codeberg.page  ← same content, without custom domain
```

### Updating the site

Merge a PR to `main`. The workflow runs automatically; the site is live within a few minutes.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Workflow not triggered | Forgejo Actions not enabled on `pages` | Enable in repo Settings → Actions |
| `git clone` fails in deploy step | `CODEBERG_TOKEN` secret missing or expired | Recreate the secret in repo Settings → Actions → Secrets |
| `Vidocq/pages` repo not found | Repository not yet created | Create an empty `pages` repo in the Vidocq org |
| Generator hangs / timeout | Roq timeout reached (default 120 s) | Increase `quarkus.roq.generator.timeout` in `application.properties` |
| Custom domain not resolving | DNS not propagated | Wait up to 24 h; check with `dig vidocq.dev CNAME` |
| Pages 404 | `.domains` file missing | Check deploy step logs; it writes the file automatically |

### Maven dependency cache

The workflow uses `actions/cache` to persist `/root/.m2/repository` between runs.
The cache key is derived from `pom.xml` — it is invalidated automatically when dependencies change.
First build: ~3–5 min. Subsequent builds with a warm cache: ~30–60 s.
