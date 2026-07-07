---
name: skill-verification-toolkit
description: >-
  Use when you are about to write ANY factual claim into a skill — a command, a
  file path, a tool flag, a quoted rule, or a "this does not exist" statement —
  and need the recipe to prove it first; also use when validating a finished
  library with scripts/validate_skills.sh, when a reviewer asks "how do you
  know that?", or when deciding whether to label something UNVERIFIED. Load
  this before authoring (Phase 2) and during factual review (Phase 3).
---

# Skill Verification Toolkit

**Core rule: no claim ships without its verifying command.** Before a fact
goes into a SKILL.md, you run a command that would have failed if the fact
were false, and you observe it succeed. "Prove it, don't just install it":
in this project that means every command, path, flag, citation, and negative
claim in a skill is backed by an observed execution, not memory.

This rule is not a preference. The project manifest (`README.md`) mandates it:

> GROUND TRUTH ONLY: verify every command, flag, path, and claim against the
> repo before stating it. Wrong runbooks are worse than none.

(Quote verified verbatim — see Recipe 4 for how.)

**Definitions used below:**

| Term | Meaning |
|---|---|
| Claim | Any sentence in a skill a reader could act on: "run X", "file Y exists", "flag Z does this", "the README says W", "there is no CI". |
| Verifying command | A command whose observed output confirms the claim, run in the actual repo before writing. |
| Paste-compare | Run the command, paste its real output into your working notes, and check the skill's description of the output against the paste — shape, not vibes. |
| UNVERIFIED label | An explicit inline marker in the skill telling the reader a command was written from knowledge, not from an observed run. |
| Negative claim | A claim that something does NOT exist ("this repo has no test suite"). |

---

## The verification ledger (do this per skill)

While drafting, keep a two-column scratch list: *claim → command that proved
it*. Every recipe below feeds this ledger. Before you finish a skill, walk the
draft line by line; any actionable claim with an empty right-hand column
either gets verified now, gets the UNVERIFIED label, or gets deleted.

Checklist before a skill is done:

- [ ] Every fenced command was run in this repo, or carries an UNVERIFIED label (Recipe 1)
- [ ] Every file path was checked with `test -f` / `test -d` / `ls` (Recipe 2)
- [ ] Every flag was checked against the tool's own `--help`, not memory (Recipe 3)
- [ ] Every quotation was matched verbatim with `grep -F` (Recipe 4)
- [ ] Every negative claim shows the search that came back empty (Recipe 5)
- [ ] `scripts/validate_skills.sh` passes on the whole library (below)

---

## Recipe 1 — Command verification

**Claim type:** "Run this command; you will see this."

**Procedure:**

1. Run the exact command you intend to write, in the repo, from the repo root
   (skills give repo-root-relative commands unless stated otherwise).
2. Paste-compare: does the real output match the shape the skill describes?
   If the skill says "prints one line per branch" and you got a pager, an
   error, or three warnings first — fix the skill text, not your memory of it.
3. Record the exit code when the skill reasons about success/failure
   (`echo "exit=$?"` immediately after).
4. Copy the command into the skill *from your terminal*, not retyped.

Worked example from this repo (run 2026-07-06):

```sh
git log --oneline --all
```

Observed output — exactly two commits, which is why sibling skills may state
"this repo has a 2-commit history" as fact:

```
c321e16 Enhance README with skill library development phases
c30ac04 Initial commit
```

**When the command cannot be run** — it is destructive (`git push --force`,
`rm -rf`), needs credentials you don't have, or needs infrastructure that
doesn't exist here — you may still include it, but you MUST mark it:

```markdown
> UNVERIFIED (2026-07-06): not run — requires push access. Written from the
> git documentation; verify against `git push --help` before relying on it.
```

An unlabeled unrun command is the single worst defect a skill can ship,
because the reader cannot distinguish it from a proven one.

**Gotchas (heuristics, not repo facts):**
- Commands that page (`git log`, `man`) behave differently in a pipe; verify
  the form you actually write (add `| head`, `--no-pager`, etc. and re-run).
- A command that "works" from your shell may depend on your `cd`; always
  re-run from the repo root before pasting.
- Verify the *whole pipeline*, not just the first command in it.

---

## Recipe 2 — Path verification

**Claim type:** "File/directory X exists (at this path)."

Every path mentioned in a skill gets checked. No exceptions — paths are the
easiest thing to hallucinate and the cheapest to verify.

```sh
test -f README.md && echo "EXISTS: README.md"   # files
test -d .claude/skills && echo "EXISTS: dir"    # directories
ls .claude/skills/                              # enumerate, don't assume names
```

Verified in this repo (2026-07-06): the working tree contains only
`README.md`, `LICENSE`, `.claude/`, and `.git/`. Proof of the full tracked
inventory:

```sh
git ls-files
```

Observed output:

```
LICENSE
README.md
```

Caution about `rg --files` as an inventory tool: ripgrep **skips hidden
files and directories by default**, so `rg --files` here also prints only
`LICENSE` and `README.md` — the entire `.claude/skills/` tree is invisible
to it (verified 2026-07-06: `rg --files --hidden -g '!.git'` does list the
skill files). Use `git ls-files` to test tracked-ness and add `--hidden` to
`rg` when hidden directories matter; the two commands measure different
things. If a path check fails, do not "fix" the path from memory —
enumerate the parent directory with `ls` and use what is actually there.

For paths a skill *tells the reader to create* (outputs, new files), say so
explicitly: "create `scripts/foo.sh`" is a plan, not a claim, and needs no
existence check — but never phrase a planned path as an existing one.

---

## Recipe 3 — Flag verification

**Claim type:** "Tool T's flag `--x` does Y."

Check the tool's own help output on the machine where the skill will run —
not your memory, not a blog post. Flags drift across versions; memory drifts
faster.

```sh
git --version                 # pin the version you verified against
git log --help | grep -F -- '--oneline'
rg --help | grep -F -- '--files'
```

Rules:

- Use `grep -F --` so the flag string is matched literally (`-F`) and not
  parsed as a grep option (`--` ends option parsing).
- If the flag does not appear in `--help`, check the man page next; if it
  appears nowhere, it does not go in the skill.
- When a skill's correctness depends on version-specific behavior, record
  the version in the skill's Provenance section. Versions observed in this
  environment on 2026-07-06: `ripgrep 14.1.0`, `git version 2.43.0`.
- Verifying the flag exists is the floor. If the skill describes the flag's
  *behavior*, verify that with Recipe 1 (run it and paste-compare).

---

## Recipe 4 — Citation verification

**Claim type:** "The source doc says: '…'" (quoting README.md, a manifest, a
license, another skill).

Quoted rules must appear **verbatim** in the source. Verify with fixed-string
grep against the file:

```sh
grep -Fn "GROUND TRUTH ONLY" README.md
```

Observed (2026-07-06): match on line 44 — which licenses the quote at the top
of this skill.

```
44:- GROUND TRUTH ONLY: verify every command, flag, path, and claim against the repo before stating it. Wrong runbooks are worse than none.
```

Rules:

- `-F` (fixed string) is mandatory: it stops regex metacharacters in the
  quote (`.`, `*`, `(`) from silently matching something you didn't quote.
- Grep for a distinctive substring of the quote if the full quote spans
  lines; then eyeball the surrounding lines (`grep -Fn -A2 -B2 ...`) to
  confirm the rest.
- No match ⇒ you are paraphrasing, not quoting. Either fix the quote to match
  the source exactly, or drop the quotation marks and mark it a paraphrase.
- Paraphrases are allowed but must not strengthen the source's claim
  (doctrine review in Phase 3 hunts for exactly this — see
  `multi-agent-review-campaign`).

---

## Recipe 5 — Negative-claim discipline

**Claim type:** "X does not exist in this repo."

A negative claim is only as good as the search behind it. The skill (or your
ledger) must show the search that failed — the command AND its empty result —
otherwise the claim is "I didn't look", not "it isn't there".

Template:

```sh
ls .github 2>&1; echo "exit=$?"        # CI config?
rg -l "pytest" .; echo "exit=$?"       # test suite references?
```

Verified in this repo (2026-07-06): `ls .github` errors —
`ls: cannot access '.github': No such file or directory` (exit 2) — and
`rg -l "pytest" .` returns no matches (exit 1). But the second result is
narrower than it looks: `rg` **skips hidden files and directories by
default**, so that search never entered `.claude/`. Re-run as
`rg -l "pytest" . --hidden -g '!.git'` and it finds two hits — skill prose
under `.claude/skills/` (this file and `repo-discovery-playbook`) mentions
pytest. So the claim the plain search licenses is only: this repo has no
`.github/` directory and *no pytest reference outside the hidden `.claude/`
directory*. Scoping the claim to what the search actually covered is the
whole discipline of this recipe.

Rules:

- **Exit codes matter:** both `rg` and `grep` exit `1` on zero matches (and
  `2` on error). An empty screen with exit `2` is a broken search, not an
  absence. Always print the exit code when recording a negative result.
- Scope the claim to the search: `rg -l "pytest" .` searches only the
  *non-hidden, non-ignored* working tree — `rg` skips hidden files and
  directories by default (add `--hidden`), skips ignored files (add
  `--no-ignore`), and never searches git history. "No pytest anywhere ever"
  needs `--hidden`, plus `git log -S pytest --oneline` (empty here,
  verified 2026-07-06), plus the `--no-ignore` note if ignored files could
  matter. A search whose real scope is narrower than the claim's scope
  green-lights a false absence.
- Prefer two independent probes for load-bearing absences (e.g. `ls` of the
  conventional path AND an `rg` for the term). One typo'd search proves
  nothing.
- Date-stamp every negative claim. Absences un-verify themselves the moment
  someone commits.

---

## The structural validator: `scripts/validate_skills.sh`

The five recipes verify a skill's *content*. The bundled script verifies the
library's *structure* — the mechanical contract every SKILL.md must meet
(format details live in `agent-skills-format-reference`).

**What it checks, per `<skills-dir>/*/SKILL.md`:**

| Check | Failure it catches |
|---|---|
| Frontmatter block present (`---` on line 1, closed later) | Skill will not load at all |
| `name:` equals the directory name | Broken trigger/identity |
| `description:` is at least 80 characters (folded `>-`/multi-line scalars are concatenated first) | Description too thin to trigger |
| A `Provenance` section heading exists | No re-verification trail |
| A `When NOT to use` section heading exists | No routing to sibling skills |

**Usage (run from the repo root):**

```sh
bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh
# or against another library:
bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh path/to/.claude/skills
```

It prints one `PASS <skill>` or `FAIL <skill>: <reasons>` line per skill plus
a summary, and exits `0` only if everything passes (`1` on any failure, `2`
on bad invocation) — so it can gate a review pipeline directly:

```sh
bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh || echo "LIBRARY NOT SHIPPABLE"
```

Verified run against this library on 2026-07-06 (before this skill's own
SKILL.md existed — note it correctly failed itself):

```
PASS agent-skills-format-reference
PASS failure-archaeology-mining
PASS repo-discovery-playbook
PASS skill-authoring-runbook
PASS skill-library-architecture-contract
PASS skill-library-change-control
FAIL skill-verification-toolkit: missing SKILL.md
----
checked: 7  pass: 6  fail: 1
```

Failure detection was also tested against four synthetic fixtures (wrong
`name:`, 9-char description, missing frontmatter/sections, and one good
skill): each produced the expected FAIL/PASS line and overall exit `1`. The
script needs only POSIX shell utilities (`sed`, `awk`, `basename`) plus
`grep`, and runs identically under `bash` and `sh`.

**Limits (be honest about them):** the validator checks structure only. It
cannot tell a verified command from a hallucinated one — that is what the
five recipes and the Phase-3 factual review are for. A library can be 100%
PASS and still be full of lies.

---

## When NOT to use this skill

- **Deciding whether a change needs review, or how to land it** — that is
  process, not proof: use `skill-library-change-control`.
- **Learning the SKILL.md format itself** (frontmatter fields, directory
  layout, scripts/ convention) — use `agent-skills-format-reference`; this
  skill's validator enforces that contract but does not teach it.
- **Initial exploration of an unfamiliar repo** (what exists, how it builds)
  — use `repo-discovery-playbook`; verification assumes you already know
  what claim you want to prove.
- **Digging through git history for past failures** — use
  `failure-archaeology-mining`.
- **Running the full adversarial review of a finished library** — use
  `multi-agent-review-campaign`; it consumes this toolkit's recipes as its
  factual-review method, but owns the campaign structure.
- **Prose quality, tone, scannability** — use `skill-writing-style`. A
  claim can be perfectly verified and still badly written.

---

## Provenance and maintenance

All repo facts above were verified on **2026-07-06** against the working
tree at that date. Re-verification one-liners:

| Claim | Re-verify with |
|---|---|
| Tracked files are only README.md and LICENSE | `git ls-files` |
| Repo history is 2 commits | `git log --oneline --all` |
| README GROUND-TRUTH quote is verbatim (line may drift) | `grep -Fn "GROUND TRUTH ONLY" README.md` |
| No `.github/` dir; no pytest reference outside the hidden `.claude/` tree | `ls .github; rg -l "pytest" .; echo "exit=$?"` (expect exit=1; `rg -l "pytest" . --hidden -g '!.git'` finds the two known skill-prose hits) |
| Validator passes on the whole library | `bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh` |
| Validator still catches breakage | Temporarily rename a skill's `name:` field and confirm a FAIL line + exit 1, then restore |
| Tool versions verified against | `rg --version; git --version` (were: ripgrep 14.1.0, git 2.43.0) |

The five recipes are method (stable guidance); the repo facts and version
numbers are volatile and must be re-verified after any commit. The example
validator output above is a snapshot — it will differ once this skill and
later siblings exist; only the PASS/FAIL format and exit-code contract are
stable claims.
