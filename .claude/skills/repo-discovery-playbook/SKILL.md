---
name: repo-discovery-playbook
description: Use when you are dropped into an unfamiliar repository and must understand it before writing any skill, doc, or code — Phase-1 discovery. Load this when asked to "investigate the repo", "figure out how this project builds/tests", "survey the codebase", or before authoring skills for a project you have not read yet. Gives copy-pasteable enumeration commands (docs, build system, tests, CI, git history, TODO hotspots) with interpretation guidance and a hard exit criterion.
---

# repo-discovery-playbook

Phase-1 discovery: investigate a repository like an incoming principal engineer BEFORE you write anything about it. The project manifest (`README.md` in this repo) mandates this phase explicitly: "Discover before you write (no skill authoring yet)."

**Definition — Phase 1**: the manifest's first stage. You read, run read-only commands, and take notes. You do not author skills, do not edit files, do not run mutating git commands.

**Definition — discovery**: building an evidence-backed answer to five questions — what the project does, how it builds, how it tests, what changed recently, what stalled — plus an explicit list of what the repo *cannot* tell you.

## Ground rules for the whole playbook

- Every command below is read-only. If a step would require `git add/commit/checkout/push`, you are outside discovery — stop.
- Record what you find AND what you don't find. A verified absence ("no CI config exists — checked `.github/workflows/`, none present") is a first-class finding. An assumed absence is a bug waiting to happen.
- Run commands from the repo root. All commands below assume that.

## Step 1 — Enumerate the documentation surface

```bash
ls -A
git ls-files
find . -maxdepth 2 -iname 'README*' -o -iname 'CONTRIBUTING*' -o -iname 'CHANGELOG*' -o -iname 'LICENSE*' -not -path './.git/*'
find . -name '*.md' -not -path './.git/*'
ls docs/ doc/ 2>/dev/null
```

**Interpretation:**

| Observation | Meaning |
|---|---|
| `git ls-files` output ≪ `ls -A` output | Untracked files exist — generated data, local config, or work in progress. Inspect them; do not document them as repo facts. |
| `README.md` present | Read it IN FULL, first, before anything else. It is usually the project's manifest and may contain rules that bind you. |
| `CONTRIBUTING.md` present | Read it second — it typically states the real test/review workflow. |
| `docs/` present | Skim every filename; read anything titled architecture, design, ADR, or runbook. |
| Only README + LICENSE | The repo is spec-only. The README *is* the project. (This is exactly the case in this repo — see "This repo's discovery result" below.) |

## Step 2 — Detect the build system

Do not guess the ecosystem; look for its manifest file.

```bash
ls package.json pyproject.toml setup.py Cargo.toml go.mod Makefile CMakeLists.txt build.gradle pom.xml Gemfile mix.exs 2>/dev/null
```

**Interpretation:**

| File found | Ecosystem | Where the real commands live |
|---|---|---|
| `package.json` | Node/JS | `"scripts"` block — read it, don't assume `npm test` |
| `pyproject.toml` / `setup.py` | Python | `[tool.*]` sections; look for pytest/tox/hatch config |
| `Cargo.toml` | Rust | `cargo build` / `cargo test` are safe defaults |
| `go.mod` | Go | `go build ./...` / `go test ./...` are safe defaults |
| `Makefile` | Any | Run `grep -E '^[a-zA-Z_-]+:' Makefile` to list targets |
| `CMakeLists.txt` | C/C++ | Expect an out-of-tree `cmake -B build` flow |
| None of the above | No build system | Record as verified absence. Nothing "builds" here. |

Two manifests at once (e.g. `Makefile` + `package.json`) usually means the Makefile wraps the ecosystem tool — the Makefile is the operator interface; read it first.

## Step 3 — Find how tests are ACTUALLY run

The single most common discovery error is assuming the conventional test command. The authoritative sources, in priority order:

```bash
ls .github/workflows/ 2>/dev/null && cat .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```

```bash
# Node: the scripts block is the contract
cat package.json 2>/dev/null | sed -n '/"scripts"/,/}/p'
# Python: pytest/tox configuration
grep -n -A5 '\[tool.pytest' pyproject.toml 2>/dev/null; ls tox.ini pytest.ini conftest.py 2>/dev/null
# Generic: test-shaped scripts
ls scripts/ bin/ 2>/dev/null | grep -i test
```

**Interpretation:** CI config outranks convention — if CI runs `make check` and the README says `npm test`, CI is what gates merges, so `make check` is the real test command. If no CI config exists, the manifest's script block is next-best. If neither exists, write "no test entry point found (verified: no `.github/workflows/`, no build manifest)" — never invent one.

## Step 4 — Inspect CI and deploy conventions

```bash
ls -A .github/ .gitlab-ci.yml .circleci/ Jenkinsfile .buildkite/ 2>/dev/null
find . -name 'Dockerfile*' -o -name 'docker-compose*' -o -name '*.tf' -not -path './.git/*' 2>/dev/null
```

**Interpretation:** CI files tell you the gate (what must pass); Dockerfiles/Terraform tell you the deploy shape. Absence of all of these is common and fine — record it as a verified absence.

## Step 5 — Mine git history breadth-first

Breadth first: shape of the whole history before depth on any commit.

```bash
git log --oneline --stat          # what changed, per commit, current branch
git log --all --oneline           # includes commits only reachable from other branches — catches dead/stalled branches
git branch -a                     # local + remote branches
git log --all --oneline --graph --decorate | head -50   # topology: merges, divergence
```

**Interpretation:**

| Observation | Meaning |
|---|---|
| `--all` shows commits absent from `main`'s log | Work exists on side branches — possibly stalled or abandoned. Diff them: `git log main..<branch> --oneline` |
| Branches in `git branch -a` with no unique commits | Setup/automation artifacts, not stalled work |
| Commit messages containing "revert", "back out", "undo" | A fought-and-lost battle — flag it for the failure-archaeology pass |
| Very short history (1–3 commits) | Young or spec-only project; history mining will be thin — say so, don't pad |

This step only *locates* dead ends. Interpreting reverts, stalls, and dead branches in depth is the job of the sibling skill `failure-archaeology-mining` — hand your branch/revert list to that pass.

## Step 6 — TODO/FIXME hotspots

```bash
rg -n 'TODO|FIXME|HACK|XXX' .
rg -c 'TODO|FIXME|HACK|XXX' . | sort -t: -k2 -rn   # per-file counts, hottest first
```

**Interpretation:** files with many hits are where the team knows the code is weak — prime skill/doc material. Beware false positives in prose: a README that *mentions* "TODO/FIXME hotspots" matches the pattern without being a hotspot (this exact false positive occurs in this repo's README.md, line 4 — verified 2026-07-06). Only count matches in code comments or issue-shaped text as real debt.

## Step 7 — Issue-shaped artifacts and generated-data conventions

```bash
find . -iname 'TODO*' -o -iname 'NOTES*' -o -iname 'BACKLOG*' -o -iname 'ISSUES*' -not -path './.git/*'
cat .gitignore 2>/dev/null
```

**Interpretation:** `.gitignore` is a map of what the project generates but doesn't track — build outputs, data dirs, local env files. Each ignored directory pattern is a convention worth one line in your notes ("`out/` is generated, never hand-edited"). Files named TODO/NOTES/BACKLOG are the project's informal issue tracker; read them fully.

## Exit criterion — when discovery is DONE

Discovery is complete when you can answer all five, each backed by a command you ran:

- [ ] **What does the project do?** (from README/manifest, not inference)
- [ ] **How does it build?** (manifest file found, or verified absence)
- [ ] **How is it tested?** (CI/scripts evidence, or verified absence)
- [ ] **What changed recently?** (`git log --oneline --stat`)
- [ ] **What stalled or was reverted?** (`git log --all` + branch diff, or "nothing — history is N commits")

Whatever you still cannot answer becomes your question list for the project owner — **at most five questions** (the manifest sets this cap). Compressing unknowns into those five is its own craft: use the sibling skill `owner-interview-protocol` for that step. Do not ask the owner anything the repo already answers; that burns a question slot and your credibility.

## This repo's discovery result (worked example, verified 2026-07-06)

This table is the **single home** for this repo's baseline facts (tracked
files, commit count, branch state); sibling skills cross-reference it rather
than restating — one home per fact. Running this playbook on
`fable-5-train-opus-skills-after-it-retires` yields:

| Question | Answer | Evidence |
|---|---|---|
| What does it do? | It is a specification for building `.claude/skills/` libraries; README.md is the manifest | `cat README.md` |
| How does it build? | No build system — verified absence | `git ls-files` → only `LICENSE`, `README.md` |
| How is it tested? | No tests, no CI — verified absence | no `.github/`, no manifests present |
| What changed? | 2 commits: initial commit, then README expansion | `git log --oneline --stat` |
| What stalled? | Nothing — one setup branch (`claude/github-repo-setup-*`), no unique work beyond the README commit | `git log --all --oneline`, `git branch -a` |

Consequence: because the repo contains no application code, "the project" this skill library documents is the skill-library authoring practice that README.md itself defines. That is why every sibling skill here is about authoring, verifying, reviewing, and maintaining skill libraries — not about an application. Any skill that pretends otherwise is inventing facts.

## When NOT to use this skill

- **You already finished discovery and want to mine history in depth** (reverts, dead ends, stalled investigations) → use `failure-archaeology-mining`.
- **You are formulating the questions for the project owner** → use `owner-interview-protocol`; this skill only tells you when you've earned the right to ask.
- **You are ready to author skills** → use `skill-authoring-runbook` (pipeline) and `agent-skills-format-reference` (file format).
- **You need to verify a specific claim before writing it into a skill** → use `skill-verification-toolkit`; this skill is for the initial broad survey, not per-claim proof.
- **The repo is already well known to you** from a prior session with intact notes — re-run only Step 5 (history) and Step 6 (TODOs) to catch drift, then defer to `skill-library-maintenance`.

## Provenance and maintenance

All repo-specific claims verified 2026-07-06 against commit `c321e16` (tip of `main`). Re-verify before trusting:

- Repo still contains only README.md + LICENSE: `git ls-files`
- History still 2 commits, no extra work on side branches: `git log --all --oneline`
- Branch set unchanged: `git branch -a`
- No build/test/CI files have appeared: `ls package.json pyproject.toml Makefile Cargo.toml go.mod 2>/dev/null; ls .github/workflows/ 2>/dev/null`
- TODO-pattern matches still limited to the README's own prose: `rg -n 'TODO|FIXME|HACK|XXX' . --glob '!.claude'`
- Manifest still mandates discovery-first and the five-question cap: `sed -n '3,4p' README.md`

The command tables in Steps 1–7 describe standard git/ripgrep/POSIX behavior and general ecosystem conventions (labeled as such); they drift only if those tools change. The interpretation guidance is heuristic, not repo fact.
