# AGENT.md — Master Prompt & Context Pack

> **Purpose.** Boot a new full-stack agent into this repository with zero ramp-up.
> Read this end-to-end before touching anything. Everything below is either
> verified against the working tree (2026-04-19) or flagged as in-flight/stale.
> When in doubt: trust the code over this file and update this file after.
>
> **Companion file: [`HANDOFF.md`](./HANDOFF.md)** — tactical per-PR playbook for
> the second-wave series (C2–C6 + P1–P2). AGENT.md tells you *where you are*;
> HANDOFF.md tells you *what to edit next, on which line, with what content*.
> Read AGENT.md §1, §7, §8 first, then jump to HANDOFF.md for the work itself.

---

## 1. Identity of the repo

- **What it is.** The course website for **SUTD 50.005 "Computer System Engineering"** — a static documentation site, published to GitHub Pages at `https://natalieagus.github.io/50005/`.
- **What this clone is.** A local checkout of **a fork** belonging to the user (`dnoma`). Purpose: contribute upstream via PRs.
  - `origin`  → `https://github.com/dnoma/50005.git` (the fork)
  - `upstream` → `https://github.com/natalieagus/50005.git` (the canonical course site owned by the course instructor, Natalie Agus)
- **Contribution workflow.** Standard fork model: feature branch off `main` → push to `origin` → open PR against `upstream/main`. Keep branches focused and single-purpose; the instructor reviews.
- **Authoring audience.** Sophomore ISTD students at SUTD. Half the course is Operating Systems, half is Networking & Security. The site is also used for labs, problem sets, and programming assignments.
- **NOT a Next.js / Vercel / Node app.** `package.json` exists only to pull in Prettier + Stylelint dev-deps inherited from the upstream `just-the-docs` theme. Ignore Vercel/Next.js auto-suggestions.

---

## 2. Stack at a glance

| Layer | Tech | Notes |
|---|---|---|
| Site generator | **Jekyll 4.4.x** | Ruby-based static site. |
| Theme | **just-the-docs 0.4.0.rc2** | Vendored — the repo *is* a fork of this theme with course content layered on top. `just-the-docs.gemspec` at the root, theme assets under `_layouts/`, `_includes/`, `_sass/`, `assets/`. |
| Markdown | **kramdown** (+ `kramdown-parser-gfm`) | GFM-ish flavour. Line numbers disabled (`_config.yml`). |
| Syntax highlighting | **Rouge** | Via kramdown. |
| Diagrams | **Mermaid 9.1.6** | Enabled via `mermaid:` key in `_config.yml`. |
| Math | **MathJax** | Included via `_includes/mathjax.html`. |
| SEO | `jekyll-seo-tag` | Only enabled plugin. GitHub Pages–compatible. |
| CSS | SCSS under `_sass/` | Themed via `color_scheme: nil` (light default). |
| Ruby | 3.0 (Docker) / 3.1 (CI) / bundler 2.3.27 | Gemfile.lock is `.gitignore`'d — each env bootstraps its own. |
| Node | only for `prettier` + `stylelint` | Scripts: `npm test` (stylelint scss), `npm run format`. |
| CI / deploy | `.github/workflows/build-pages.yml` | On push to `main`, builds with `JEKYLL_ENV=production` and deploys to GitHub Pages. Only *upstream's* `main` deploys publicly. |

---

## 3. Directory map (what lives where)

```
.
├── _config.yml               Site config — baseurl "/50005", url "natalieagus.github.io".
│                             Defines callouts, nav, mermaid version, search, footer.
├── _config_docker.yml        Overrides for the docker-compose path (sets url: "").
├── Gemfile / *.gemspec       Ruby deps; site is built as the theme gem against itself.
├── Dockerfile, docker-compose.yml
├── .devcontainer/            VS Code devcontainer wiring.
├── serve.sh                  Local dev script (LOCAL-ONLY — see §10).
│
├── index.md                  Home page (nav_order: 1).
├── 404.html
│
├── _layouts/                 Theme HTML layouts. `default.html`, `page.html`, `home.html`,
│                             `about.html`, `post.html`, `notoc.html`, `table_wrappers.html`.
│                             Prefer authoring course content with `layout: default`.
├── _includes/                Partials: nav.html, head.html, mathjax.html, mermaid_config.js,
│                             footer_custom.html, header_custom.html, title.html, favicon.html,
│                             css/, js/, icons/, vendor/.
├── _sass/                    Theme SCSS: base, buttons, code, content, labels, layout, modules,
│                             navigation, print, search, tables, typography, color_schemes/,
│                             custom/, support/, utilities/, vendor/.
├── assets/                   css/, js/, images/, contentimage/. Course-authored assets live here
│                             and under the per-section `docs/*/images/` folders.
├── lib/, bin/                Theme CLI bits (just-the-docs gem); do not edit for content work.
│
├── docs/                     ** ALL COURSE CONTENT **
│   ├── OS/                   Operating Systems half (Weeks 1–6).
│   │   ├── 01-os-intro.md ... 12-directories.md
│   │   ├── 08-synchronization.md   (1,333 lines — the spine; see §8)
│   │   ├── 09-csync.md       Summer-2026 C-track replacement for...
│   │   ├── 09-javasync.md    ...the Java-track chapter (being phased out; nav-excluded).
│   │   ├── index.md          OS landing page + weekly learning objectives.
│   │   ├── workflows/, images/
│   ├── NS/                   Networking & Security half (Weeks 7–12).
│   │   ├── 01-network-basics.md ... 09-http-web.md
│   │   ├── index.md, images/
│   ├── Labs/                 01–09 lab writeups. Note the 2026 C-track dupes:
│   │                         05-Lab5-Bankers{-2026}.md, 07-Lab7-Encryption{-2026-c}.md,
│   │                         09-Lab9-HTCPCP{-2026}.md.
│   ├── Problem Set/          01–11 tutorial sheets mapped to weekly topics.
│   ├── Programming Assignment/  pa1/, pa2/, index.md.
│   ├── roadmap-os.md, roadmap-ns.md, chatbot.md, usefulresources.md
│
├── .github/workflows/build-pages.yml   GitHub Pages deploy (see §2).
├── package.json              Prettier + Stylelint only. Ignore.
├── node_modules/             Tracked? No — `.gitignore`d.
├── _site/                    Build output. `.gitignore`d.
├── .jekyll-cache/            Incremental build cache. `.gitignore`d.
│
├── README.md                 2 sentences — "content is in /docs, PRs welcome".
├── PEDAGOGY_AUDIT.md         The user's private audit — NOT upstream. See §8.
├── AGENT.md                  This file — tracked on fork's main only (see §10).
└── HANDOFF.md                Tactical per-PR playbook for §8.2 series (see §10).
```

---

## 4. Content authoring conventions

Every content page lives under `docs/**/` and uses this frontmatter pattern:

```yaml
---
layout: default            # nearly always; `notoc` / `home` for special pages
permalink: /os/processes   # absolute site path (baseurl gets prepended at render)
title: Processes           # sidebar + <title> text
description: How are processes managed by the OS?   # subtitle + SEO
parent: Operating System   # parent nav group (matches the group's index.md title)
nav_order: 5               # numeric order within the group
# nav_exclude: true        # hide from sidebar — used for in-progress pages
# has_children: true       # for index.md of a group
---

* TOC
{:toc}

**50.005 Computer System Engineering**
<br>
Information Systems Technology and Design

# Actual Title
{: .no_toc}
```

### Callouts (defined in `_config.yml:104-128`)

Always prefer the theme's callout system over inline `<span style="color:#…">` tags:

```markdown
Install POSIX-Compliant OS before the first Lab session in Week 1.
{:.important}
```

Available: `highlight`, `important`, `new`, `info`, `note`, `warning`, `error`, `task`.
Base level is `callouts_level: quiet` (muted), upgrade to `loud` per-page if needed.

### Common gotchas

- **`baseurl: "/50005"`** — all asset references must use `{{ site.baseurl }}/…` or a leading `/` that will be rewritten by the theme. Hardcoded `/assets/…` breaks on GitHub Pages.
- **Code fences mislabelled** — several `cpp` fences contain C. Pick `c` or `cpp` deliberately; syntax highlighting follows the label.
- **Image filenames are rot-prone** — `week3/1.png`, `week3/2.png`, … Prefer descriptive names when adding new images.
- **`nav_exclude: true` hides the page** from the sidebar but keeps the URL live. Used intentionally for the Java track during the C-track migration; double-check before toggling.
- **Permalinks use `pretty` style** — no trailing `.html`. Don't hard-code extensions in internal links.
- **Last-modified timestamps** — add `last_modified_date: YYYY-MM-DD HH:MM:SS +0800` to enable the footer stamp (`last_edit_timestamp: true` site-wide).

### Mermaid & MathJax

- **Mermaid** fenced as ` ```mermaid `. Version pinned 9.1.6 — do not bump without testing the pages that use it.
- **MathJax** via `$…$` / `$$…$$`. Include works globally; no per-page toggle needed.

---

## 5. Local development

### Option A — the committed script (preferred)

```bash
./serve.sh              # default port 4000
./serve.sh 4001         # override port
```

What it does (bash, idempotent):
1. `cd` to repo root.
2. Sets bundler's path to `vendor/bundle` (avoids polluting system gems).
3. `bundle install` only when `Gemfile` is newer than `Gemfile.lock` or `vendor/bundle` missing.
4. `bundle exec jekyll serve --host 0.0.0.0 --port $PORT --livereload --incremental`.

Requires: Ruby 3.0+ and `gem install bundler`.

### Option B — Docker

```bash
docker compose up      # exposes http://localhost:4000
```

Uses `Dockerfile` (ruby:3.0, bundler 2.3.27) + `_config_docker.yml` (sets `url: ""`, so links work on localhost instead of `natalieagus.github.io`).

### Option C — devcontainer

`.devcontainer/` is wired for VS Code "Reopen in Container". Same image as docker-compose.

### Quick-build sanity check

```bash
bundle exec jekyll build                      # writes to _site/
bundle exec jekyll build --baseurl ""         # mimic local paths
JEKYLL_ENV=production bundle exec jekyll build # mimic CI
```

### Linting (only scoped to theme SCSS)

```bash
npm install
npm test               # stylelint '**/*.scss'
npm run format         # prettier --write on scss/js/json
```

These are inherited from upstream just-the-docs; they are **not required** by CI for this fork. Run before an upstream PR only if it touches `.scss`.

---

## 6. Deployment (CI)

- Workflow: `.github/workflows/build-pages.yml`.
- Trigger: push to `main` + manual `workflow_dispatch`.
- Runner: `ubuntu-latest`, Ruby 3.1, bundler cache keyed on `Gemfile`.
- Builds with `JEKYLL_ENV=production` and `--baseurl "${{ steps.pages.outputs.base_path }}"`.
- Publishes `./_site` as a Pages artifact, then `actions/deploy-pages@v4`.
- Only **upstream's** `main` is the public site. The fork's `main` deploys to `dnoma.github.io/50005/` **only if** the user enables Pages on the fork; otherwise CI runs but nothing goes live.

---

## 7. Branching state (as of 2026-04-19)

### Upstream status

The **first wave of 4 PRs merged upstream** (commits now part of `natalieagus/50005 main`):

| # | Branch | What it did |
|---|---|---|
| #11 | `fix/csync-highlight-callout-typo` | SCSS / callout usage fix in the C-sync chapter. |
| #12 | `fix/csync-highlight-callout-typo` | (merge commit `80dff5e`) |
| #13 | `fix/ipc-broken-next-chapter-ref` | Fixed the off-by-one "next chapter" link in `06-ipc.md`. |
| #14 | `fix/unhide-synchronization-chapter` | Removed `nav_exclude: true` from `08-synchronization.md`. |
| —   | `docs/os-sync-spurious-wakeup` | Spurious-wakeup subsection + while-vs-if explainer at `08-sync.md:743`. Merged around the same time. |

Upstream HEAD at last sync was **`b151b9f chore: fix nav order`** on `upstream/main`.

### Local branches (fork only)

- **`main`** — **intentionally diverges from `upstream/main` by exactly two files**: `AGENT.md` and `serve.sh` (see §10). Everything else on `main` is a rebase of upstream.
- **`docs/os-intro-syscall-trace`** — **active PR** (commit `56b7454`, pushed `2026-04-19`). Adds "Tracing a System Call" subsection to `docs/OS/01-os-intro.md`. PR URL: `https://github.com/dnoma/50005/pull/new/docs/os-intro-syscall-trace`. See §8.2 — this is **PR 1 of ~10** in the second-wave series. **Branched off `upstream/main`, not `origin/main`**, so AGENT.md / serve.sh don't leak into the PR diff.
- Deleted: `preview/all-four`, `fix/unhide-synchronization-chapter`, `fix/ipc-broken-next-chapter-ref`, `fix/csync-highlight-callout-typo`, `docs/os-sync-spurious-wakeup` (merged upstream or superseded).

### Why `main` diverges (and how to keep it that way)

The fork's `main` is not used for PRs — **PR branches start from `upstream/main` directly** (see §9 recipe). Two invariants:

1. Fork's `main` = upstream's `main` + our local tooling (AGENT.md, serve.sh). Nothing else.
2. PR branches carry only the content diff. AGENT.md never appears in an upstream PR.

When upstream moves, **rebase** (don't fast-forward) `main`:

```bash
git fetch upstream --prune
git checkout main
git rebase upstream/main               # keeps the AGENT.md/serve.sh commit on top
git push --force-with-lease origin main
```

**Do not `git merge --ff-only upstream/main` into `main` anymore** — it only succeeds when `main` has no local commits, which is no longer true.

---

## 8. Pedagogy audit & in-flight editorial work

### 8.1. Source of the work

`PEDAGOGY_AUDIT.md` is the user's private critique of the OS half of the course — kept local, **not** for upstream. It drives every PR in §8.2.

Headline findings (read the file for details):

1. ✅ **Nav excluded the core sync chapter** — fixed in first-wave PR.
2. ✅ **Broken forward reference** in `06-ipc.md` — fixed in first-wave PR.
3. ✅ **Dangling rhetorical "Why?"** on spurious wakeups — fixed in first-wave PR.
4. ⏳ **Ch 08 is three chapters fused into one** (1,333 lines) — deferred; structural reorg, pitch later.
5. ⏳ **Banker's Algorithm outsourced to lab** (`10-deadlock.md:343,350`) — **out of current scope** (weeks 1–8 only).
6. ⏳ Plus ~15 smaller gaps — scaffolding, missing worked examples, absent diagrams, missing retrieval prompts, inline-`<span>` anti-patterns.

### 8.2. Second-wave PR series — weeks 1–8 (OS chapters 01–08)

**Tactical spec** for every row below lives in **`HANDOFF.md`** (repo root, tracked on `main` only). Read that file before starting C2 onward — it has problem statements, exact insertion points, line numbers, content sketches, and commit templates.

**Scope.** Confirmed with the user: chapters `01-os-intro.md` → `08-synchronization.md`. **Networking, deadlock, filesystem are out of scope.**

**Lens.** A student who has never touched OS/kernels trips on (in order): (1) vocabulary avalanche, (2) no mental model of the machine, (3) theory before motivation, (4) missing middle step between formula and exercise, (5) pitfalls taught as footnotes.

**Rollout strategy.** Content PRs first (low structural risk, high comprehension payoff), then pitch structural PRs once momentum is established. **One PR per branch; one concern per PR.**

| ID | Branch | Chapter | Description | Status |
|---|---|---|---|---|
| **C1** | `docs/os-intro-syscall-trace` | 01 | Seven-step trace of a `read()` syscall — user→syscall→kernel→return. Reference anchor for later chapters. | **✅ pushed `56b7454`, PR pending** |
| **C2** | `docs/os-design-unified-diagram` (planned) | 03–04 | Unify the four OS-design diagrams (simple / layered / microkernel / modular) onto one comparative figure. | ◻ not started |
| **C3** | `docs/os-processes-fork-trace` (planned) | 05 | Program-vs-process side-by-side; traced `fork()` with both parent + child PCBs. | ◻ |
| **C4** | `docs/os-ipc-socket-primer` (planned) | 06 | Primer for `bind`/`listen`/`accept` before the socket example dumps them on the reader. | ◻ |
| **C5** | `docs/os-threads-amdahl-worked` (planned) | 07 | One worked numeric Amdahl's Law example + mini speedup-vs-N table. Resolves `07-threads.md:473`. | ◻ |
| **C6** | `docs/os-sync-peterson-trace` (planned) | 08 | Peterson's interleaving diagram + explicit pitfall boxes (`volatile` misconception, fork+mutex, stack-return from pthread). Builds on the merged spurious-wakeup subsection. | ◻ |
| **P1** | `chore/os-spans-to-callouts` (planned) | 01–08 | Migrate remaining inline `<span style="color:…">` tags to the theme's callout system. | ◻ |
| **P2** | `fix/os-code-fence-langs` (planned) | 01–08 | Correct code-fence language labels (`cpp` → `c` where C is actually shown). | ◻ |
| **S1** | `docs/os-glossary` (post-content) | all | New `docs/OS/glossary.md` with ~40 recurring terms, auto-linked on first use per chapter. | ◻ deferred |
| **S3** | `docs/os-self-check-blocks` (post-content) | 01–08 | Standard "Before you start" + "Self-check" (3 recall Qs) blocks per chapter. | ◻ deferred |

**Not pursued (yet).** S2 ("mental-model of the machine" canonical diagram at top of Ch 01) — fold into Ch 01 only if prof signals appetite; C1 already gives the conceptual anchor.

### 8.3. C-track migration (2026)

`09-csync.md` is dated *Summer 2026*; most other chapters say *Summer 2025*. `09-javasync.md` is `nav_exclude`d. Labs have 2026-suffixed dupes (`05-Lab5-Bankers-2026.md`, `07-Lab7-Encryption-2026-c.md`, `09-Lab9-HTCPCP-2026.md`). The course is migrating examples from Java to C.

**Rule.** Do not "fix" a Java example in a file being replaced. If unsure, check whether a `*-2026*.md` or `09-csync.md` version already handles it.

---

## 9. Recipes (the common tasks, pre-written)

### Add a new chapter to `docs/OS/` or `docs/NS/`

1. Create `docs/OS/NN-slug.md` with standard frontmatter (see §4).
2. Set `parent: Operating System` (or `Networking & Security`) and pick a `nav_order` that slots cleanly.
3. Add content; include `* TOC\n{:toc}` near the top for the right-rail TOC.
4. If it introduces new imagery, drop files under `docs/OS/images/<week>/descriptive-name.png` and reference with `{{ site.baseurl }}/docs/OS/images/…`.
5. Local preview: `./serve.sh`. Check sidebar slots correctly and the TOC renders.

### Start a new PR from the §8.2 series

The canonical "new fix" workflow — PR branches start from **`upstream/main`**, not `origin/main`, so the fork's local tooling never appears in the PR diff:

```bash
git fetch upstream --prune
git checkout -b <conventional>/<slug> upstream/main   # e.g. docs/os-processes-fork-trace
# AGENT.md and serve.sh are absent on this branch — expected.
# … edit files …
git add <file>                              # explicit paths only — never `git add -A`
git diff --cached --stat                    # sanity-check scope
# STOP — wait for the user to preview the render (rule 10, §12)
git commit -m "<type>(<scope>): <subject>"  # NO Co-Authored-By trailer (rule 9)
git push -u origin <conventional>/<slug>
# open PR against upstream:main via the GitHub link git prints
```

When the PR merges upstream, sync the fork's `main`:

```bash
git fetch upstream --prune
git checkout main
git rebase upstream/main                    # preserves the AGENT.md/serve.sh commit on top
git push --force-with-lease origin main
```

**Conventional-commit prefixes used in this repo.** `docs(...)` for prose/content additions, `fix(...)` for broken references/links/typos, `chore(...)` for theme / tooling / local-only, `feat(...)` reserved for anything the instructor classes as new teaching content.

### Fix a typo / single-line edit

Same workflow as above, just tiny. Prefix with `fix(os-XX): …`.

### Replace inline `<span>` with a callout

```diff
-<span style="color:#ff0000">Do not ignore this.</span>
+Do not ignore this.
+{:.error}
```

### Rebase a fix branch after upstream moves

```bash
git fetch upstream
git checkout fix/<slug>
git rebase upstream/main
# resolve, then:
git push --force-with-lease origin fix/<slug>
```

---

## 10. Local-only files

Three are **tracked on the fork's `main` only** (they live with the repo so `git clone` brings them along, but never appear in upstream PRs):

- `AGENT.md` — this file; master orientation / context pack.
- `HANDOFF.md` — tactical playbook for the second-wave PR series (§8.2). Delete once the series is complete.
- `serve.sh` — local dev convenience script.

Two are **gitignored, never tracked**:

- `PEDAGOGY_AUDIT.md` — the user's private audit.
- `.idea/` — JetBrains IDE state.

### Updating AGENT.md, HANDOFF.md, or serve.sh

Do the edit on `main` directly; they're normal tracked files:

```bash
git checkout main
# … edit AGENT.md / HANDOFF.md / serve.sh …
git add <file>
git commit -m "chore(local): <subject>"
git push origin main                  # fork only — upstream has no write permission
```

### Why they don't leak into PRs

PR branches are created from `upstream/main` (see §9 recipe), not from `origin/main`. `upstream/main` has no AGENT.md / serve.sh, so the PR diff only contains the content changes.

**Never use `git add -A` or `git add .`** on this repo. Always stage explicit paths. If you accidentally branch off `origin/main` instead of `upstream/main`, the AGENT.md/serve.sh commit will travel with the branch; rebase onto `upstream/main` to drop it:

```bash
git rebase --onto upstream/main main~1 <fix-branch>
```

### Memory files (outside the repo)

User's Claude auto-memory at `/Users/marcus/.claude/projects/-Users-marcus-Documents-Postgraduate-CSE/memory/`:

- `project_50005_fork.md` — fork/upstream identity (duplicates some of §1; source of truth is this file).
- `feedback_no_coauthor_trailer.md` — no `Co-Authored-By` or AI attribution on commits (see rule 9).
- `feedback_test_before_push.md` — stage-then-stop; wait for user preview before committing (see rule 10).

---

## 11. Non-obvious facts future-you will thank us for

- `Gemfile.lock` is **git-ignored** — do not commit it. Each environment (local, Docker, CI) resolves its own.
- `just-the-docs.gemspec` makes the repo a self-consuming gem: `Gemfile` → `gemspec` pulls the theme in from the repo itself. Editing `_layouts/` or `_sass/` changes the site directly; there's no upstream theme to fight.
- Search is client-side (lunr) — rebuild the site after adding content to see new results.
- `aux_links` and `nav_external_links` in `_config.yml` add the top-right links; keep them in sync when the instructor's preferences change.
- `compress_html` is on — don't chase mysterious whitespace issues in view-source; that's expected.
- `heading_anchors: true` auto-adds `#anchors` to headings — cross-link with `/os/synchronization#peterson-s-solution` syntax.
- Callouts with emoji titles (📢 Important, 💡 Info, 📘 Note, ⚠️ Warning, 🧨 Caution, 🎯 Task) are configured in `_config.yml`; don't re-invent titles inline.
- The **fork's `main`** may drift behind upstream — `git fetch upstream && git log main..upstream/main` before starting a new fix to avoid working against stale context.

---

## 12. Agent operating rules (how to behave in this repo)

1. **Minimal, focused diffs.** Each PR fixes one thing. The instructor reviews faster and merges more.
2. **Frontmatter is load-bearing.** Do not break `parent:`, `nav_order:`, or `permalink:` without a clear reason — you will silently move the page off the sidebar.
3. **Respect the C-track migration.** If touching a Java example, check whether the C replacement already exists in `09-csync.md` / `*-2026*.md` before editing.
4. **Use the callout system, not inline CSS.** Accessibility + maintainability.
5. **Verify links before claiming "fixed".** `./serve.sh` and click through. Kramdown will silently render a broken `[text](url)` as plain text.
6. **Never commit `_site/`, `node_modules/`, `.jekyll-cache/`, `Gemfile.lock`, or `vendor/`.**
7. **PR branches come from `upstream/main`, not `origin/main`.** The fork's `main` carries AGENT.md + serve.sh; branching off `origin/main` would drag them into the PR diff.
8. **When a memory file or this AGENT.md disagrees with the code, trust the code and update the doc.**
9. **No `Co-Authored-By: Claude` trailer. No AI attribution in commits or PR bodies, ever.** Commits go in under the user's name only. Plain conventional-commit subject + body — do not append `Co-Authored-By: Claude …`, "Generated with Claude Code", or any equivalent footer.
10. **Stage edits, then stop — do not commit until the user has previewed the render.** On this repo the rendered Markdown (callout classes, kramdown links, list-inside-callout indentation, mermaid blocks) can surface issues that a diff review misses. Wait for explicit "go" before `git commit`.

---

## 13. Hand-off checklist for the next agent

Read §1, §7, §8.2, §12 in that order — they are the load-bearing context. Then **open [`HANDOFF.md`](./HANDOFF.md)** for the per-PR playbook. Then:

1. **`git fetch upstream --prune`** and compare `upstream/main` against the HEAD recorded in §7 (currently `b151b9f`). If upstream has moved, scan the new commits — the §8.2 / HANDOFF.md progress columns may be out of date.
2. **Check which §8.2 branch is next** — cross-reference the ledger at the bottom of HANDOFF.md. C1 (`docs/os-intro-syscall-trace`) was pushed `2026-04-19`; confirm whether it merged upstream, then pick up C2 → C3 → C5 → C4 → C6 → P2 → P1 per HANDOFF.md's suggested order.
3. **Open `HANDOFF.md` for the PR you're about to do.** It has the exact file, insertion point, line numbers, content sketch, and commit-message template. Don't skip ahead — every spec includes "verify line numbers before editing" because upstream merges drift them.
4. **Also re-open `PEDAGOGY_AUDIT.md`** for the chapter you're touching — it's the source motivation for HANDOFF.md and sometimes has extra context.
5. **Use the §9 "Start a new PR" recipe verbatim.** Branch off `upstream/main`, not `origin/main`.
6. **Respect rules 9 + 10 in §12.** No co-author trailer. Stage, then stop — wait for user render preview before `git commit`.
7. **Update both files as you go.** Mark rows ✅ in §8.2 *and* in HANDOFF.md's ledger once merged upstream. Bump the "Last verified" date below. If a new convention emerges, add it to §11 or §12. When HANDOFF.md's ledger is fully ✅, delete that file in a `chore(local):` commit — AGENT.md persists, HANDOFF.md is disposable.

---

*Last verified against working tree: 2026-04-19 (post-C1 push, post branch-model simplification). Branch: `main`. Upstream HEAD: `b151b9f`. Regenerate any section if it drifts; keep this file the single source of truth for agent onboarding.*
