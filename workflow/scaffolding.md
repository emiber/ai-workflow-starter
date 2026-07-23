# Scaffolding — defining architecture and stack

Guide for `/init-project`. The goal is, through questions, to define the project's components, suggest technologies, and generate the minimal base. Apply the principles in `principles.md`: don't propose components the project doesn't need.

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

### 4. Confirmation and generation

Before creating files:

1. Summarize the chosen architecture in a short list.
2. Ask for explicit confirmation.
3. Generate:
   - `docs/ARCHITECTURE.md` with the decisions (including deferred ones and why), plus the Quality gate (coverage threshold — default 85% — and how it's measured).
   - Minimal folder structure for the chosen components.
   - Base files: **extend** the baseline `.gitignore` that ships with the template with stack-specific entries (don't replace it — it already excludes `.env` and secrets), the project `README.md` (replace the placeholder root README with one describing the project — what it is and how to run it; leave `workflow/README.md` untouched), linter/formatter config, a test runner set up to report coverage, `.env.example` with the placeholder config your stack needs, `docker-compose.yml` if it applies, and the dependency manifest (`package.json` / `pyproject.toml` / etc.) with only what's needed.
   - `.github/workflows/ci.yml` filled in for the chosen stack: on every PR to `main` **or an epic integration branch (`epic/**`)** — so child PRs of an epic are gated too (see `workflow/epics.md`) — run lint + tests and fail if coverage is below the threshold in `docs/ARCHITECTURE.md` (default 85%). Keep the `on.pull_request.branches` filter that ships with the template (`main` and `epic/**`); replace the placeholder guard step with real setup/install/lint/test steps, and rename the workflow back to `name: CI` and the job to a real name.
   - **No** dependencies or component folders that weren't confirmed.

## Golden rule

The generated scaffolding has to start and run (even if it's a "hello world" per component). Don't leave a skeleton that doesn't compile.

## Template integrity check

After scaffolding, do a quick, lightweight self-check (no extra tooling — just verify, and fix what's off):

1. **Referenced files exist.** Every `workflow/*.md` and doc referenced by `CLAUDE.md`, `AGENTS.md`, and `.github/copilot-instructions.md` (including `workflow/rules.md`), plus the command/skill definitions under `.claude/commands/` and `.agents/skills/`, are present.
2. **`.workflow-config` is valid.** It has `issue_tracker=github` or `issue_tracker=jira` (and `jira_project=...` when Jira).
3. **No leftover placeholders.** The root `README.md` no longer contains the "bootstrapped from the AI Workflow Starter" placeholder, and `docs/ARCHITECTURE.md` has real decisions instead of `_(pending)_`.
4. **CI is initialized.** `.github/workflows/ci.yml` no longer has the "template not initialized" guard step and runs real lint/test/coverage.

Report anything still off; don't silently leave the template half-initialized.
