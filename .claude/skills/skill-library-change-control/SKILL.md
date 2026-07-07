---
name: skill-library-change-control
description: >-
  Use when adding, editing, correcting, or deleting any skill under
  .claude/skills/ in this repository, when deciding whether a proposed change
  needs review, when preparing to commit or push skill changes, or when a
  request appears to conflict with the rules in README.md. Defines the change
  classes (new skill, factual correction, style edit, deletion), the review
  each requires, the five non-negotiable rules with their rationale, and the
  pre-merge checklist. Load this BEFORE modifying any file in the library.
---

# Change control for the skill library

## What this skill governs

**Change control** = the rules for classifying, gating, and reviewing every
modification to the skill library at `.claude/skills/`. A **skill library** is
a set of `SKILL.md` files (one per directory) that lets a zero-context engineer
or Sonnet-class model carry the project forward. The **manifest** is the
project's rule-of-record document — in this repository, that is `README.md` at
the repo root; it is the only project documentation that exists here besides
`LICENSE` (verified 2026-07-06: `git ls-tree -r --name-only HEAD` lists exactly
`LICENSE` and `README.md`).

Honesty note, load-bearing: this repository contains no application code. The
"project" the library documents is the skill-library authoring practice that
`README.md` itself specifies. Change control here therefore governs changes to
documentation about that practice — which makes factual accuracy the entire
product. There is no compiler or test suite to catch a lie for you.

## The five non-negotiables

These come from the AUTHORING RULES section of `README.md` (lines 41–48).
Each is stated with its rationale, because a rule whose reason is forgotten
gets rationalized away. No incident history exists for these rules — the
repo's 2-commit history contains no reverts (verified 2026-07-06 with
`git log --oneline --all`; repo context: see `repo-discovery-playbook`'s
discovery-result table). The rationales below are the manifest's stated
reasoning plus its direct implications, not war stories.

### 1. GROUND TRUTH ONLY

Every command, flag, path, and claim in a skill must be verified against the
repository before it is stated as fact. The manifest's own words: "GROUND
TRUTH ONLY: verify every command, flag, path, and claim against the repo
before stating it. Wrong runbooks are worse than none."

**Rationale:** the audience is a Sonnet-class model or zero-context engineer.
They will follow a runbook *literally* — they cannot tell a plausible
invention from a verified fact, and they lack the context to notice when a
command fails for the wrong reason. A wrong runbook therefore actively
misleads; an absent runbook merely leaves the reader to investigate. This
inverts the usual "some docs are better than none" instinct. Corollary rules:

- Negative claims ("this repo has no CI") must be phrased as **verified
  absences** with the command that verified them.
- Judgment-based guidance is allowed but must be **labeled** as guidance or
  heuristic, never presented as repo fact.
- Verification method: run the command in the repo, or read the file, before
  writing the sentence. See sibling `skill-verification-toolkit` for the
  how-to.

### 2. Write only inside `.claude/skills/`

During authoring, the rest of the repository is read-only. Manifest wording:
"Write ONLY inside `.claude/skills/`; the rest of the repo is read-only."

**Rationale:** the library documents the project; it must not silently
*become* the project. If an authoring agent edits `README.md` (the manifest),
it can rewrite the rules it is being judged against — the documentation would
then be validating itself against a target it moved. Confining writes to
`.claude/skills/` keeps the ground truth stable while many parallel agents
write against it, and makes every authoring change trivially auditable
(`git status --porcelain -uall` should list individual files, all under
`.claude/skills/`; without `-uall`, git collapses untracked directories to
a single `?? .claude/` entry, which hides the per-file detail).

### 3. No mutating git commands during authoring

No `git add`, `git commit`, `git push`, `git checkout`, `git rebase`,
`git reset`, or anything else that changes the index, HEAD, branches, or the
remote. Manifest wording: "no mutating git commands." Committing and pushing
is a **separate step, gated by a human or by the orchestrator** — never
performed by an authoring or review agent on its own initiative.

**Rationale:** authoring is parallel (many agents, one library) and
review comes *after* all skills exist (the manifest's Phase 3). A commit made
mid-authoring (a) can clobber or race sibling agents' work, (b) freezes
unreviewed content into history, and (c) collapses the authoring/review/merge
separation that makes the review meaningful. Keeping the worktree dirty until
an explicit gated step means the entire library lands as one reviewable unit.

### 4. No oversell

Unproven claims stay labeled `open` or `candidate`. Manifest wording: "No
oversell: unproven things stay labeled open/candidate."

**Rationale:** a Sonnet-class reader calibrates its confidence from the
document's confidence. If a skill states an untested heuristic in the same
voice as a verified fact, the reader will bet on it as fact and propagate the
error into code, commits, and further docs. Labels (`open`, `candidate`,
`heuristic`, `unverified`) are the mechanism that lets one document safely mix
certainty levels. The open-problems register lives in sibling
`skill-library-research-frontier` — do not restate its problems as solved
anywhere else.

### 5. Nothing contradicts the manifest; no routing around change control

No skill may contradict `README.md`, and no skill may describe a procedure
that bypasses the gates in this skill. Manifest wording: "Nothing may
contradict the project's own manifest/rules, and no skill may route around
its change-control."

**Rationale:** the library is many documents with one source of authority.
The moment two documents disagree, a zero-context reader has no way to pick
the right one — so contradiction with the manifest is treated as a defect in
the *skill*, always, and fixed there. "Routing around" means any skill text
like "for small edits you can skip re-verification" or "trivial fixes can be
committed directly": such text, wherever it appears, is a change-control
violation even if the skill is otherwise accurate. One home per rule: the
gates live here; siblings link here instead of restating (and possibly
mutating) them.

## Change classes and required review

Classify every proposed change before touching a file. If a change spans
classes (e.g., a factual correction that also restructures prose), apply the
**strictest** applicable row.

| Class | Definition | Required review before merge |
|---|---|---|
| **New skill** | A new `<skill-name>/SKILL.md` directory | Full three-lens review (factual, doctrine, usability — see sibling `multi-agent-review-campaign`); frontmatter check (`name` equals directory name, `description` states when to load); "When NOT to use" section present and pointing at a real sibling; "Provenance and maintenance" section present with dated re-verification commands |
| **Factual correction** | Changing any command, flag, path, count, quote, or claim | **Re-verification evidence required**: the exact command run (or file read) that proves the new claim, executed in this repo, with its output — attach it to the change description. A correction without evidence is just a second unverified claim replacing the first |
| **Style edit** | Wording, formatting, section order; zero change to any factual claim | Confirm the diff is fact-neutral: read the diff and check no command, path, number, or label (`open`/`candidate`) was altered. Style rules live in sibling `skill-writing-style` — conform to it, do not restate it |
| **Deletion** | Removing a skill directory or a whole section | **Cross-reference check required** (command below): no surviving sibling may still point at the deleted skill or section. Also confirm any fact whose only home was the deleted text is either obsolete or re-homed first |

### Deletion cross-reference check

Before deleting skill `<name>`, prove nothing else references it:

```bash
# Run from the repo root
rg -n '<name>' .claude/skills/ --glob '!<name>/**'
```

Expected output for a safe deletion: **nothing** (ripgrep exits 1 on zero
matches). Any hit is a sibling cross-reference that must be updated in the
same change, before or together with the deletion.

### Factual-correction evidence format

Attach to the change (commit message, PR body, or review note):

```text
CLAIM CHANGED: <old claim> -> <new claim>
VERIFIED BY:  <exact command>
OUTPUT:       <relevant output lines>
DATE:         <YYYY-MM-DD>
```

Then update the skill's own "Provenance and maintenance" section if the
correction changes what needs future re-verification.

## Pre-merge checklist

Run every row before the gated commit step. All rows must pass for every
changed skill.

| # | Check | Command / method | Pass condition |
|---|---|---|---|
| 1 | Writes confined to the library | `git status --porcelain -uall` | Every listed path starts with `.claude/skills/` (expected shape: one `?? .claude/skills/...` or ` M .claude/skills/...` line per file; `-uall` is required — without it git collapses untracked directories to `?? .claude/`, which would falsely fail this check) |
| 2 | No mutating git commands were run | `git log --oneline -3` and `git stash list` | History unchanged since authoring began; no new stashes |
| 3 | Frontmatter valid | Open the SKILL.md; check `name:` equals its directory name and `description:` says when to load it | Both true |
| 4 | Every stated command runs | Copy-paste each fenced command from the changed skill into a shell at the repo root | Exits as the skill says it does |
| 5 | Negative claims are verified absences | For each "there is no X" claim, find the verifying command in the skill | Command present and re-runs clean |
| 6 | Unproven content labeled | `rg -in 'open|candidate|heuristic|guidance' <changed SKILL.md>` and read surrounding text | Every judgment-based claim carries a label |
| 7 | No manifest contradiction | Re-read `README.md` lines 41–48 against the diff | No conflict; no text that waives a gate |
| 8 | Cross-references resolve | For each sibling skill named in the changed file: `ls .claude/skills/<sibling>/SKILL.md` | File exists |
| 9 | Deletions cross-ref-checked | Command in the Deletion section above | Zero matches |
| 10 | Provenance section current | Check the "Provenance and maintenance" date-stamp of the changed skill | Updated to the date of this change |

Only after all ten pass does the change go to the **gated commit step**: a
human or the orchestrator (not an authoring agent) runs `git add` /
`git commit`. That step is outside this skill's actor; this skill's job ends
at handing over a checklist-clean worktree.

## When NOT to use this skill

- **Writing a brand-new skill from scratch** and you need the end-to-end
  authoring pipeline (discovery → author → review), not the gating rules:
  use `skill-authoring-runbook`. Come back here to classify and gate the
  result.
- **You need to verify a specific claim** (how to prove a command, path, or
  absence): use `skill-verification-toolkit`. This skill only says *that*
  evidence is required, not how to produce it.
- **Prose and formatting questions** (voice, tables, section order): use
  `skill-writing-style`.
- **Running a full adversarial review of the whole library** (Phase-3 style,
  multiple reviewers): use `multi-agent-review-campaign`. This skill defines
  what each change class must clear; that one defines how a campaign is run.
- **Ongoing drift detection and periodic re-verification** after the library
  is merged: use `skill-library-maintenance`.
- **Questions about SKILL.md format mechanics** (frontmatter fields, loading
  behavior): use `agent-skills-format-reference`.
- **Why the library is designed the way it is** (load-bearing decisions, not
  gates): use `skill-library-architecture-contract`.

## Provenance and maintenance

Facts in this skill and how to re-verify them. Date-stamped 2026-07-06.

| Claim | Re-verification command (run at repo root) |
|---|---|
| Repo contains only `LICENSE` and `README.md` (plus `.claude/skills/`) | `git ls-tree -r --name-only HEAD` |
| History is exactly 2 commits, no reverts, all branches | `git log --oneline --all` |
| The five non-negotiables and their wording are in `README.md` lines 41–48 | `sed -n '41,48p' README.md` |
| Sibling skills named here exist | `ls .claude/skills/` |
| No CI config exists in this repo (verified absence) | `ls -A .github 2>/dev/null; ls .gitlab-ci.yml Jenkinsfile 2>/dev/null` — expect errors/empty |
| Cross-reference check command still finds nothing for a candidate deletion | `rg -n '<name>' .claude/skills/ --glob '!<name>/**'` |

If `README.md` changes (its AUTHORING RULES section especially), this skill
is **stale until re-reconciled**: re-read the manifest first, update the
quoted line ranges and wording here, and treat the reconciliation itself as a
factual correction under the table above.
