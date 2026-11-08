# Scaffolding — defining architecture and stack

Guide for `/init-project`. The goal is, through questions, to define the project's components, suggest technologies, and generate the minimal base. Apply the principles in `principles.md`: don't propose components the project doesn't need.

## Pre-check: existing ARCHITECTURE.md

Before starting the question flow, check whether `docs/ARCHITECTURE.md` already exists in the project root and, if it does, whether it's still the unfilled template the starter ships. It is when the **Project type** section still reads `_(pending)_` and no other section has real content. What the template ships with doesn't count as content: the headings and the intro note, any `_(pending…)_` placeholder with its label, the empty Tech stack row, the Deferred decisions placeholder line (`_(things we decided NOT…)_`), and the fixed Quality gate lines such as `Coverage threshold: 85% (default)` and `Enforced identically…`, as long as they're unchanged. Anything else is real content. When in doubt, treat the file as a real design: a wrong call then costs one question, not the user's work.

- **If it exists and isn't the unfilled template:** show its contents to the user and ask:
  > `docs/ARCHITECTURE.md` already exists. Do you want to **(a)** redo the design questions and overwrite it, or **(b)** skip to code generation using the existing file?
  - Answer **a** → proceed with the full question flow below, then overwrite the file.
  - Answer **b** → before entering 4b, do a quick sanity check of the file: warn the user about every placeholder starting with `_(pending` that it contains (such as `_(pending)_` and the Quality gate's `_(pending — e.g. …)_`), except in the **License** section, which is handled below, and about a missing coverage threshold or missing Quality gate commands, and ask them to fix those before continuing. If the file records no license choice (no **License** section, or a placeholder there), or a recorded value that step 3's check wouldn't accept (a key `gh api licenses/<key>` rejects, or a `[fullname]` license without a holder), don't ask the user to fix that by hand: ask step 3's license question, check the key as it says, and record the answer in a **License** section before 4b moves anything. Also warn: step 4b will regenerate the base files (README, `ci.yml`, etc.) from the existing `ARCHITECTURE.md` — any manual edits to those files will be overwritten. The baseline `.gitignore` is the exception: 4b extends it with stack-specific entries instead of regenerating it. Confirm the user is aware before proceeding. If they confirm, skip directly to **step 4b**.
  - **Any other answer** → re-ask with the same two options.
- **If it does not exist, or is still the unfilled template:** don't ask (a)/(b). Say why in one line (e.g. "`docs/ARCHITECTURE.md` is still the unfilled template, so I'll start the design questions." or "There's no `docs/ARCHITECTURE.md` yet, so I'll start the design questions."), then proceed with the full question flow below. Step 4a writes the file (replacing the template, if it's there).

## Question flow

Ask **one at a time or in small groups**, not all at once. After each answer, adjust the following questions.

### 1. Project type

Ask what's being built. Typical categories:

- API / backend service
- Full-stack web application
- SPA / frontend only
- CLI / tool
- Worker / batch or queue processing
- Library / package
- Monorepo with several of the above

### 2. Required components

Based on the type, confirm which components are needed. **Don't assume: ask which ones apply.**

- **API**: REST, GraphQL, gRPC? Public or internal? Authentication?
- **Frontend**: SSR or SPA? Does it need SEO?
- **Database**: relational or document? Expected volume? Transactions?
- **Cache**: is it needed? (don't add it by default)
- **Queues / messaging**: is there real async work, or is it premature?
- **File storage**: blobs, images?
- **Auth**: your own, or a provider (Auth0/Clerk/Cognito)?
- **Observability**: logs, metrics, tracing.

> Apply YAGNI: if the user says "maybe in the future we'll need queues", don't add them now. Note it as a deferred decision in `ARCHITECTURE.md`.

### 3. Technologies

For each confirmed component, **suggest options with a short reason and ask**. Don't impose. Examples of default suggestions (boring and proven):

| Component | Default suggestion | Alternatives to mention |
|---|---|---|
| Backend | Node + TypeScript (Fastify/Express) or Python (FastAPI) | Go, .NET, Java Spring |
| Frontend | React + Vite + TypeScript | Next.js (if it needs SSR/SEO), Svelte, Vue |
| Relational DB | PostgreSQL | MySQL, SQLite (for small/embedded projects) |
| Document DB | MongoDB | DynamoDB, Firestore |
| ORM/query | Prisma / Drizzle (TS), SQLAlchemy (Py) | plain query builder |
| Queues | Redis + BullMQ (small), RabbitMQ / SQS (serious) | Kafka only if there's real streaming |
| Cache | Redis | in-memory if it's a single node |
| Auth | Managed provider (Clerk/Auth0) | your own only with a strong reason |
| Tests | Vitest/Jest (JS), pytest (Py) | — |
| Containers | Docker + docker-compose for local dev | — |

> **Windows / cross-platform note:** Avoid packages that require native compilation (node-gyp).
> They fail on Windows machines without Visual Studio Build Tools. Specific cases to watch:
> - SQLite: use **`@libsql/client`** (prebuilt binaries, no compilation) — not `better-sqlite3`.
> - Image processing: `sharp` has prebuilt binaries; `canvas` requires node-gyp — avoid it.
> - Any package whose install runs `node-gyp rebuild` is a red flag unless prebuilt binaries
>   exist for the target Node version and OS.
> If the user's environment is Windows (or unknown), default to pure-JS / WASM / prebuilt-binary
> alternatives and note the trade-off.

Also ask about the user's preferences (language they know well, cloud they already use, client constraints). Their preferences win over the default suggestions.

Also ask which **license** the project uses, so it doesn't inherit the starter's MIT `LICENSE` without anyone deciding it. Three answers:

- **No license**: no root `LICENSE`. This is the default when the user doesn't know or skips the question; say so in chat. Having no license grants no rights, the safe default for a project that may be private.
- **MIT** (key `mit`): the starter's MIT text with the current year and a copyright holder the user gives. Ask for the holder.
- **Another license**, named by its GitHub license key (`gh api licenses` lists the common ones; the lookup is case-insensitive). Check the key right away with `gh api licenses/<key>`. On a 404 (e.g. the SPDX id `GPL-3.0-only`; GitHub's key is `gpl-3.0`), say so and re-ask, showing the keys `gh api licenses` lists; don't map it to another license yourself. For GNU `-only`/`-or-later`, the user picks `gpl-3.0` and the like: the license text is the same, and that choice goes in source headers. If the check fails for another reason (offline, not authenticated), say so and re-ask: the user can fix `gh` and give the key again, or pick no license or MIT, which need no lookup. Ask for the holder only when the license text has `[fullname]`.

A license whose text has `[fullname]` (MIT always does) is recorded only with a holder. If the user won't give one, don't record it holder-less: re-ask, or offer the choices that need none (no license, or a license whose text has no `[fullname]`).

Step 4a records the choice as one line in the **License** section of `docs/ARCHITECTURE.md`: `none`, or the key plus the holder when one was asked (e.g. `mit — Acme Inc.`, `apache-2.0`). Step 4b applies it.

### 4a. Design phase — emit ARCHITECTURE.md and pause

After the question flow is complete:

1. Summarize the chosen architecture in a short list (in chat).
2. Write `docs/ARCHITECTURE.md` with the decisions (including deferred ones and why), plus the Quality gate: coverage threshold (default 85%), how it's measured, and the exact **lint** and **test-with-coverage** commands. Those two commands are the single definition of the gate — CI runs them and `/work-issue` runs them before every PR. Fill in its **License** section with the license choice from step 3.
3. **Stop.** Tell the user:
   > `docs/ARCHITECTURE.md` has been written. Review it and reply **"continue"** (or **"proceed"** / **"looks good"**) to generate the project files — or describe what you'd like to change.

Do **not** generate any code, folders, or other files at this point. Wait for an explicit positive reply before entering step 4b.

**Handling the user's reply at this pause:**

- **Positive reply** ("continue", "proceed", "looks good", "yes", "go ahead", "generate") → enter step 4b.
- **Change request** ("change X to Y", "use MongoDB instead", etc.) → apply the change to `docs/ARCHITECTURE.md`, then **re-pause** with the same prompt. Do not advance to 4b automatically. If the change sets a license value that step 3's check wouldn't accept (a key `gh api licenses/<key>` rejects, or a `[fullname]` license without a holder), treat it as unrecorded: ask and check it as step 3 says before re-pausing.
- **Abort / restart** ("abort", "start over", "no", "cancel", "stop") → offer two options: restart from the question flow (go back to step 1, overwriting `ARCHITECTURE.md` at the end of the new flow) or stop entirely and leave the file as-is for later. Do not enter step 4b.
- **Ambiguous reply** (a question, "interesting", "hmm", partial agreement with an open question) → answer or clarify, then re-display the pause prompt. Do not interpret ambiguous replies as confirmation.

### 4b. Generation phase — create the project files

Only after the user confirms (or after arriving here from the pre-check with an existing `ARCHITECTURE.md`):

1. Generate:
   - Minimal folder structure for the chosen components.
   - Base files: **extend** the baseline `.gitignore` that ships with the template with stack-specific entries (don't replace it — it already excludes `.env` and secrets), the project `README.md` (replace the placeholder root README with one describing the project — what it is and how to run it; leave `workflow/README.md` untouched), linter/formatter config, a test runner set up to report coverage, `.env.example` with the placeholder config your stack needs, `docker-compose.yml` if it applies, and the dependency manifest (`package.json` / `pyproject.toml` / etc.) with only what's needed.
   - `.github/workflows/ci.yml` filled in for the chosen stack: on every PR to `main` or an epic integration branch (`epic/**`), run lint + tests and fail if coverage is below the threshold in `docs/ARCHITECTURE.md` (default 85%). Child PRs of an epic target `epic/**`, so they must be gated too (see `workflow/epics.md`); keep the `on.pull_request.branches` filter that ships with the template. Replace the placeholder guard step with real setup/install steps plus the lint and test-with-coverage commands recorded in `docs/ARCHITECTURE.md` (the same commands, not variants), and rename the workflow back to `name: CI` and the job to a real name. Leave `.github/workflows/workflow-check.yml` as is — it checks the workflow files, not the stack.
   - **No** dependencies or component folders that weren't confirmed.
2. **License.** Apply the license choice recorded in `docs/ARCHITECTURE.md`. If `workflow/LICENSE` doesn't exist and the root `LICENSE` contains the starter's copyright line `Copyright (c) 2026 Emiliano`, first move the root `LICENSE` to `workflow/LICENSE` unchanged: the project keeps the starter's workflow files, and the starter's MIT license requires its notice in copies. Only then apply the choice to the root:
   - **No license** → no root `LICENSE`.
   - **MIT** → copy `workflow/LICENSE` to the root `LICENSE` and change only its copyright line, to `Copyright (c) <current year> <holder>`.
   - **Another license** → write the root `LICENSE` from `gh api licenses/<key> --jq .body`. Replace only `[year]` (the current year) and `[fullname]` (the holder), if present, and write everything else verbatim. Apache-2.0's `[yyyy] [name of copyright owner]` and the GNU licenses' `<year>  <name of author>` are templates for per-file headers, not fields to fill. If the fetch fails (offline, not authenticated), don't guess the text and don't put the starter's MIT back at the root: leave the root `LICENSE` absent and keep the recorded choice. The integrity check reports it.

   If that condition doesn't hold, touch neither file and skip the rest of this step: `workflow/LICENSE` already exists (e.g. a rerun), or the root `LICENSE` is missing or lacks the starter's copyright line (the user replaced it or edited its holder, so it's theirs). Report which of the two files exist and whose notice each carries, keep the recorded choice, and print the command that would apply it by hand: for another license, `gh api licenses/<key> --jq .body > LICENSE` (in Git Bash or PowerShell 7: Windows PowerShell 5.1's `>` writes UTF-16), then fill `[year]`/`[fullname]`; for MIT, copy `workflow/LICENSE` to `LICENSE` and edit its copyright line; for no license, nothing to run (a root `LICENSE` that is there is the user's to remove).

### 5. Enable branch protection on `main`

After generation, protect `main` at the platform so the "never push/merge to `main`" rule is enforced by GitHub, not just by agent discipline (a direct push otherwise runs no CI and nothing blocks it). **Attempt** it automatically; never fail the whole scaffold if it can't be done.

1. Determine the required CI check name — it is the **job name** set in `.github/workflows/ci.yml` (you renamed it from the template placeholder to a real name in step 4b). The required status check context must match it **exactly**, or the gate isn't enforced.
2. Attempt to enable protection on `main` via `gh api` (classic branch protection shown; a ruleset works too):

   ```bash
   gh api -X PUT "repos/{owner}/{repo}/branches/main/protection" --input - <<'JSON'
   {
     "required_status_checks": { "strict": true, "contexts": ["<CI job name>"] },
     "enforce_admins": true,
     "required_pull_request_reviews": { "required_approving_review_count": 0 },
     "restrictions": null
   }
   JSON
   ```

   `required_approving_review_count: 0` requires a PR without locking out a solo maintainer (who can't approve their own PR); raise it for a team that wants mandatory review. `enforce_admins: true` blocks direct pushes to `main` even for admins — that is the point.
3. **On failure — do not abort.** If the call fails (the repo isn't on GitHub yet, you lack admin, or the plan doesn't support protection), warn and print the exact manual steps instead of erroring out:
   > Couldn't enable branch protection automatically. Enable it by hand: repo **Settings → Branches → Add branch ruleset** (or **Add rule**) for `main` — require a pull request before merging, require the status check **<CI job name>** to pass, and block direct pushes (including admins). See `workflow/README.md` "Getting started".

## Golden rule

The generated scaffolding has to start and run (even if it's a "hello world" per component) and pass its own quality gate, run by the Template integrity check — or, if the gate can't run locally, report it as not run with the reason. Don't leave a skeleton that doesn't compile.

## Template integrity check

After scaffolding, do a self-check (no tooling beyond the project's own — just verify, and fix what's off, except item 5, which only reports):

1. **Workflow files are consistent.** Run `bash .github/scripts/check-workflow.sh` (the same check CI runs). It verifies that every command has its skill and delegates to it, that every skill's frontmatter has one `name` equal to its directory name and one nonblank `description` (in the small one-line form documented in the script, not a full YAML check), that every `workflow/` or `docs/` guide referenced from the entry files, commands, skills, or other guides exists (see below), that every command is listed in the entry files, and that `.workflow-config` is valid (`issue_tracker=github`, or `jira` with `jira_project=...`). Fix whatever it reports. If `bash` isn't available (e.g. Windows without Git Bash), do those same checks by hand and say so.

   **Guide references** are a bounded text check, not a Markdown link checker. The guides scanned are the visible `.md` files under `workflow/` and `docs/` at any depth; hidden files and folders are skipped, and symlinks are neither entered nor read. A reference is a whole path from the repository root, such as `workflow/git-flow.md` or `docs/<folder>/<subfolder>/<name>.md`, where each name uses only ASCII letters, digits, `_` and `-`, optionally followed by a `#fragment` in the same characters (or an empty one). It must be a regular file with no symlink anywhere in its path; the fragment isn't checked against headings. Other forms aren't checked at all (not reported, not normalized): source-relative or absolute paths (`../guide.md`), URLs and paths inside a longer path (`https://…/docs/…`, `docs/x.md.bak`, `docs/x.md?raw=1`), paths glued to `=`, `&`, `%`, `~`, `+`, `:` or `@` (`--file=docs/x.md`, `@docs/x.md`, `docs/x.md:12`), backslashes, `.`, `..` or empty parts, names with spaces, dots or non-ASCII characters, encoded names, uppercase `.MD`, queries, and any other fragment. The comment above section 3 of the script lists the exact rules.

2. **No leftover placeholders.** The root `README.md` no longer contains the "bootstrapped from the AI Workflow Starter" placeholder, and `docs/ARCHITECTURE.md` has real decisions — including the Quality gate commands — with no placeholder starting with `_(pending` left (such as `_(pending)_` or `_(pending — e.g. …)_`).
3. **CI is initialized.** `.github/workflows/ci.yml` no longer has the "template not initialized" guard step and runs the Quality gate commands from `docs/ARCHITECTURE.md`.
4. **Branch protection attempted.** `/init-project` tried to protect `main` (require a PR, require the CI check, block direct pushes) and either applied it or reported the manual steps — the required check name matches the `ci.yml` job name.
5. **License matches the choice.** The root `LICENSE` matches the license recorded in `docs/ARCHITECTURE.md`: absent for `none`; for MIT, the starter's text with the recorded holder in its copyright line; for another license, the fetched text with only `[year]`/`[fullname]` filled. The starter's holder (`Copyright (c) 2026 Emiliano`) appears at the root only if the user kept MIT under that name. `workflow/LICENSE` still holds the starter's notice, including that line. A chosen license with no root `LICENSE` is still off: report it with the command to add it later, `gh api licenses/<key> --jq .body > LICENSE` (in Git Bash or PowerShell 7: Windows PowerShell 5.1's `>` writes UTF-16), then fill `[year]`/`[fullname]`. This item is report-only: it reports any mismatch and never deletes, moves or rewrites `LICENSE` or `workflow/LICENSE` (that would undo 4b's guard, which touches neither file), and it never writes license text from memory.
6. **Quality gate passes.** Install the dependencies with the stack's normal install, the one that writes the lockfile where the stack has one (e.g. `npm install`, `uv sync`), not a locked install like `npm ci`: a fresh scaffold has no lockfile yet, so a locked install fails. Keep the lockfile it writes: it's part of the scaffold, and `ci.yml`'s locked install needs it. Then run the **lint** and **test-with-coverage** commands from the **Quality gate** section of `docs/ARCHITECTURE.md`, exactly as recorded. Both must pass.
   - **On a failure** (e.g. a hello-world below the coverage threshold, or a lint error in generated code), fix the generated code or config (add the missing tests, fix the lint error) and re-run the gate. Never lower the coverage threshold, exclude files or code from coverage, skip or delete tests, or loosen the lint config to get green (`workflow/principles.md`, "Never weaken tests to make them pass" and "Treat it as a floor, not a number to game"). If a command still fails after your fixes, report it with its output; don't hide it. If that command is the install, lint and tests are "not run: the install failed".
   - **If the toolchain isn't available locally** (e.g. the runtime isn't installed), report the gate as "not run: <reason>", never as passed. The scaffold doesn't abort.
   - **Report** the result of lint and of tests with coverage, naming each command: pass, fail with its output, or "not run: <reason>". The quality gate has passed only when both passed in this run; a gate that still fails, or wasn't run, hasn't passed.

Report anything still off; don't silently leave the template half-initialized.
