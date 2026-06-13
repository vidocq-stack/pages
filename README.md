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
.forgejo/workflows/
  deploy-pages.yaml             # CI/CD pipeline (Forgejo Actions → Cloudflare Pages)
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

## Deployment — Cloudflare Pages + Forgejo Actions

The source lives on Codeberg (`codeberg.org/Vidocq/pages`, branch `main`).
The static site is generated in CI and published to **Cloudflare Pages** (project `vidocq-site`),
which serves it on its global edge network at **https://vidocq.dev**.

```
codeberg.org/Vidocq/pages   ← source (this repo, branch: main)
        │  push to main
        ▼
   Forgejo Actions (.forgejo/workflows/deploy-pages.yaml)
        │  mvn package + Roq batch generator → target/roq/
        ▼
   wrangler pages deploy  ──►  Cloudflare Pages (project: vidocq-site)  ──►  vidocq.dev
```

### How it works

Every push to `main` (or a manual `workflow_dispatch`) triggers the Forgejo Actions workflow
(`.forgejo/workflows/deploy-pages.yaml`) that:

1. **Builds** the Quarkus Roq app with Maven, baking in `quarkus.roq.generator.batch=true`
   (Java 21 via `actions/setup-java`, Node.js 22 via `actions/setup-node`).
2. **Generates** the complete static site into `target/roq/` by running the packaged jar.
3. **Creates** the Cloudflare Pages project `vidocq-site` if it does not exist yet (idempotent).
4. **Deploys** `target/roq/` to Cloudflare Pages with `wrangler pages deploy`.

### First-time setup

#### 1. Create the Cloudflare Pages project

The workflow creates the project automatically on first run
(`wrangler pages project create vidocq-site --production-branch=main`).
You can also create it manually from the Cloudflare dashboard (**Workers & Pages → Create → Pages**)
if you prefer to configure the custom domain beforehand.

#### 2. Enable Forgejo Actions on the repository

In Codeberg: `Vidocq/pages` → **Settings → Actions → Enable**.

#### 3. Add the Cloudflare secrets

The workflow authenticates to Cloudflare with an API token. In `Vidocq/pages`,
go to **Settings → Actions → Secrets** and add:

| Secret          | Value                                                                        |
|-----------------|------------------------------------------------------------------------------|
| `CF_API_TOKEN`  | A Cloudflare API token with the **Cloudflare Pages → Edit** permission.      |
| `CF_ACCOUNT_ID` | Your Cloudflare account ID (Dashboard → any zone → right sidebar).           |

> Create the token at **Cloudflare Dashboard → My Profile → API Tokens → Create Token**,
> using the *Cloudflare Pages — Edit* template.

#### 4. Configure your runners

The workflow uses `runs-on: ubuntu-latest`.
Your self-hosted `act_runner` instances must be registered with that label (the Forgejo runner default),
and must have network access to npm (it runs `npx wrangler@latest`).

#### 5. Configure the custom domain (vidocq.dev)

In **Cloudflare Pages → vidocq-site → Custom domains**, add `vidocq.dev` (and optionally `www`).
Because the domain is managed in Cloudflare, the required DNS records are created for you and
HTTPS is provisioned automatically.

#### 6. Trigger the first deployment

Push any commit to `main`, or run the workflow manually from the **Actions** tab
(the `workflow_dispatch` trigger accepts an optional `reason` input that is recorded in the
Cloudflare deployment commit message).

#### 7. Verify

```
https://vidocq.dev               ← live site (custom domain)
https://vidocq-site.pages.dev    ← same content on the Cloudflare default domain
```

### Updating the site

Merge a PR to `main`. The workflow runs automatically; Cloudflare Pages serves the new
deployment within a minute or two. Each deployment is versioned in the Cloudflare dashboard,
so you can roll back to a previous build in one click.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Workflow not triggered | Forgejo Actions not enabled on `pages` | Enable in repo Settings → Actions |
| `wrangler` fails with auth error | `CF_API_TOKEN` / `CF_ACCOUNT_ID` missing or wrong scope | Recreate the secrets; token needs *Pages → Edit* |
| `project not found` on deploy | The create-project step was skipped or failed | Re-run; the create step is idempotent (`|| true`) |
| Generator produces no `target/roq/` | Build did not run the batch generator | Ensure `-Dquarkus.roq.generator.batch=true` is passed at package time |
| Custom domain not resolving | Domain not yet attached in Cloudflare Pages | Add it under Pages → Custom domains; wait for DNS/SSL |
| Generator hangs / timeout | Roq timeout reached (default 120 s) | Increase `quarkus.roq.generator.timeout` in `application.properties` |

### Maven dependency cache

The workflow uses `actions/setup-java` with `cache: maven` to persist the Maven local repository
between runs. The cache key is derived from `pom.xml` — it is invalidated automatically when
dependencies change. First build: ~3–5 min. Subsequent builds with a warm cache: ~30–60 s.
