---
name: skill-library-research-frontier
description: >-
  Use when asked what is unproven about skill libraries, whether this library
  measurably works, what to research or benchmark next, how to evaluate skill
  effectiveness or trigger precision, whether staleness detection can be
  automated, or whether any claim about this library may be published or
  presented as novel/proven. Loads the open-problems ledger and the
  external-positioning rule that gates public claims.
---

# Skill-library research frontier: open problems

This skill is the ledger of what this project has **not** proven. Every entry
below is **OPEN** — a candidate research problem, not a result. Nothing in
this file is a claim of achievement. If you came here looking for evidence
that skill libraries work, the honest answer as of 2026-07-06 is: **no such
evidence exists in this repo.**

Context you need: the repo tracks only `README.md` and `LICENSE` (repo
context: see `repo-discovery-playbook`'s discovery-result table; verified
2026-07-06). The "project" is the
skill-library authoring practice that `README.md` specifies, and the library
under `.claude/skills/` is both the deliverable and the only test subject
available. That makes this repo unusually well-positioned to study these
problems — the entire artifact under study is small, self-contained, and
reproducible from a single directory — but it also means every claim of
effectiveness is currently untested.

## Definitions (read once)

| Term | Meaning here |
|---|---|
| Skill library | The set of `<name>/SKILL.md` files under `.claude/skills/` that Claude Code loads on demand. |
| Sonnet-class model | A mid-tier model (cheaper, less capable than the frontier tier) — the target reader per `README.md`. |
| Matched sessions | Two agent sessions given the identical task and environment, differing only in the one variable under test (e.g., library loaded vs. not). |
| Pre-registered metric | A success metric written down, with its threshold, **before** any experimental runs — so you cannot pick the metric that flatters the result afterward. |
| Precision / recall (for triggers) | Precision: of the times a skill loaded, what fraction were moments it should have loaded. Recall: of the moments it should have loaded, what fraction it actually did. |
| Confusion table | A grid of (task phrasing × skill loaded) counts, exposing which phrasings load the wrong skill or none. |
| Drift / staleness | A fact asserted in a SKILL.md that was true at write time and is no longer true of the repo. |
| Model tier | A capability/cost class of model (e.g., Haiku-class < Sonnet-class < frontier). |

## The external-positioning rule (binding)

> **Nothing from this project may be publicly claimed as novel or proven —
> in a paper, release note, README badge, blog post, or talk — until a
> falsifiable milestone in this file has actually been met, AND the result
> is reproducible from this repo alone (no private data, no unstated
> environment).**

This is the project's only rule about external claims, and it routes through
change control like everything else: a change that adds a public claim is a
behavior-affecting change. See `skill-library-change-control` for the gating
mechanics. Corollaries:

- "We built a skill library" is a statement of work done — fine to say.
- "Our skill library improves Sonnet-class performance" is a **result claim**
  — forbidden until Problem 1's milestone is met.
- Internal documents may discuss expectations freely, but must label them
  open/candidate, exactly as this file does.

## How each entry is structured

Every open problem below has four fixed parts. When you add a new problem to
this file, use the same four:

1. **Why current practice fails** — the gap, stated without exaggeration.
2. **This project's specific asset** — what this repo has that makes the
   problem tractable *here*.
3. **First three concrete steps in this repo** — actionable today, in this
   working tree.
4. **You have a result when…** — a falsifiable milestone. If you cannot
   imagine the experiment failing, the milestone is not falsifiable; rewrite it.

---

## Problem 1 — Effectiveness measurement (OPEN)

*Does loading this library measurably improve a Sonnet-class session?*

**Why current practice fails.** Skill libraries across the ecosystem are
judged by eye: an author reads the prose, finds it plausible, and ships. No
control condition, no counting, no repetition. "It seems helpful" is
compatible with the library helping, doing nothing, or actively misleading
(a stale runbook is worse than none — `README.md` says exactly this: "Wrong
runbooks are worse than none"). Nobody in this repo, and to our knowledge
few anywhere, have run the matched-session experiment.

**This project's specific asset.** The library documents its own authoring
practice, so representative tasks are cheap to generate: every task the
library claims to enable (run Phase-1 discovery, author a new skill, verify
a claim, review the set) is a candidate benchmark task. The whole subject
fits in one directory and two files of repo content — matched sessions are
inexpensive and the environment is trivially reproducible.

**First three concrete steps in this repo.**

1. Define 5–10 representative tasks and write them, with a pre-registered
   scoring rubric, to a proposed file (path does not exist yet — creating it
   is the step):

   ```bash
   mkdir -p .claude/skills/skill-library-research-frontier/experiments
   $EDITOR .claude/skills/skill-library-research-frontier/experiments/tasks.md
   ```

   Each task entry: prompt text, ground-truth-correct outcome, and the two
   scores to record — task completion (did the session produce the correct
   outcome?) and wrong-path count (how many verifiably incorrect actions —
   invented paths, wrong commands, skipped gates — before completion?).

   Creating `experiments/tasks.md` adds new skill content to the library:
   route it through `skill-library-change-control` (New-skill-content
   change, same as the script addition in Problem 3 step 2), and reference
   the new file from this SKILL.md per `agent-skills-format-reference`'s
   overflow-file rule — an unreferenced file in a skill directory is dead
   weight.

2. Run matched sessions: for each task, one Sonnet-class session in this repo
   with `.claude/skills/` present, one with it hidden (e.g., in a scratch
   clone with the directory moved aside — never mutate this working tree).
   Same prompt, same starting state. Log full transcripts.

3. Score both arms per the pre-registered rubric and tabulate per-task
   deltas. Repeat each condition at least 3 times per task — single runs of
   stochastic models prove nothing.

**You have a result when…** a metric that was pre-registered *before* the
runs (e.g., "wrong-path count drops by ≥50% with the library loaded") shows
a repeatable difference across repeated runs — not a single anecdote, not a
post-hoc metric. A null or negative result also counts as a result and must
be recorded here just as prominently.

---

## Problem 2 — Trigger-precision measurement (OPEN)

*Do the `description:` fields actually cause skills to load at the right
moments?*

**Why current practice fails.** Descriptions are written to be "trigger-rich"
(this repo mandates ≥80 characters phrased as "Use when …"), but whether a
given phrasing actually causes the model to load the intended skill is never
measured. Authors optimize prose they believe the router reads a certain way;
the belief is untested. Two failure modes go undetected: a skill that never
fires (dead weight), and two skills that fire on each other's tasks
(confusion — plausible here between e.g. `skill-verification-toolkit` and
`skill-library-maintenance`, which share vocabulary about re-verification).

**This project's specific asset.** A complete 12-skill library with
deliberately differentiated descriptions, all in one directory, each with a
"When NOT to use" section that already states the *intended* routing. The
intended confusion table is therefore already written down — it only needs
to be measured against actual behavior.

**First three concrete steps in this repo.**

1. Enumerate a phrasing set: for each of the 12 skills, write 5–10 task
   phrasings that *should* load it, plus adversarial phrasings that should
   load a sibling instead. List the skills to cover:

   ```bash
   ls .claude/skills/
   ```

   Store the phrasing set alongside the tasks file from Problem 1
   (proposed: `experiments/trigger-phrasings.md`). Creating it is a library
   change like Problem 1's step 1: route it through
   `skill-library-change-control` and reference it from this SKILL.md per
   `agent-skills-format-reference`'s overflow-file rule.

2. For each phrasing, start a fresh session in this repo with that phrasing
   as the opening prompt and record which skill(s) load (from the session's
   own tool/skill-invocation log). One phrasing per session — carryover
   context contaminates the measurement.

3. Compute the confusion table (phrasing-intended-skill × skill-actually-
   loaded) and per-skill precision and recall from it.

**You have a result when…** every skill in the library has a measured
precision and recall over the full phrasing set, and the numbers are stable
across at least two independent measurement passes. "Skill X has recall 0.2"
is a result; so is "all skills ≥0.9". Redescribing a skill resets its
measurement to OPEN.

---

## Problem 3 — Staleness-detection automation (OPEN)

*Can drift be caught by machinery instead of a human re-reading Provenance
sections?*

**Why current practice fails.** Every skill in this library ends with a
"Provenance and maintenance" section listing one-line re-verification
commands — but running them and judging the output is manual. Manual
re-verification is exactly the kind of chore that silently stops happening.
Verified 2026-07-06: this repo has **no CI configuration** (no `.github/`
directory, no CI files anywhere in the tree), and the existing validator —
`.claude/skills/skill-verification-toolkit/scripts/validate_skills.sh` —
checks *structure only* (frontmatter, name/dir match, description length,
required section headings). It does not execute any re-verification command.

**This project's specific asset.** The re-verification commands already
exist, in a near-uniform format, in every skill's Provenance section. The
structural validator already exists and passes over the library. The gap is
narrow and well-defined: execute the one-liners, compare against expected
output.

**First three concrete steps in this repo.**

1. Survey the raw material — extract every Provenance section's fenced
   commands to see how uniform they are:

   ```bash
   grep -rn -A 20 -i '^#\{1,6\} .*provenance' .claude/skills/*/SKILL.md | less
   ```

2. Extend the validator (or add a companion script under
   `skill-verification-toolkit/scripts/` — a change routed through
   `skill-library-change-control`) to: parse each Provenance section's
   commands, execute them in the repo root, and diff actual output against
   an expected-output annotation. This requires first agreeing a
   machine-readable convention for "expected output" in Provenance sections
   — that convention is itself an open design decision; propose it via
   change control.

3. Wire it into CI — this repo currently has none, so this step includes
   creating the first workflow (e.g., a GitHub Actions file; note
   `.github/workflows/` does not exist yet and creating repo files outside
   `.claude/skills/` is gated by the project's write-scope rules — get owner
   sign-off first). The job runs the extended validator on every push and
   fails on any drift.

**You have a result when…** an *intentionally introduced* stale fact (e.g.,
edit a skill in a test branch to reference a file path that does not exist)
is caught by the automated check without any human reading the diff. The
seeded-fault test is the milestone — a green run on a clean tree proves only
that the check runs, not that it detects.

---

## Problem 4 — Transfer across model tiers (OPEN)

*Does a library tuned for Sonnet-class readers work for Haiku-class ones —
or for stronger tiers?*

**Why current practice fails.** Skill prose is calibrated to one imagined
reader. `README.md` targets "junior/mid-level engineers and smaller AI models
(Sonnet-class)". A weaker (Haiku-class) reader may need more scaffolding than
the library provides (under-specification for that tier); a stronger reader
may be slowed or misled by runbook detail it would have gotten right anyway
(over-specification). Nobody measures per-tier fit; libraries are written
once and assumed tier-portable.

**This project's specific asset.** The whole benchmark apparatus from
Problem 1 — task set, rubric, matched-session protocol — reuses directly.
Tier transfer is Problem 1 run twice with the model as the varied axis,
which is why Problem 1 must land first: its task set and rubric are the
prerequisite instrument.

**First three concrete steps in this repo.**

1. Complete Problem 1's steps 1–2 (task set + matched-session protocol) —
   do not fork the instrument; tier comparison needs the identical task set.
2. Re-run the full matched-session grid on a second tier: for each task,
   (library, no-library) × (Sonnet-class, Haiku-class), ≥3 runs per cell.
3. Compute per-tier deltas (library-minus-no-library, per tier) and compare
   them. Tag any skill whose presence helps one tier and hurts the other —
   those are the over-/under-specification candidates to revise.

**You have a result when…** the same library has been benchmarked on two
tiers with the same pre-registered task set, and per-tier deltas are
reported side by side — including the case where the deltas are equal (a
transfer-positive null) or where the library hurts a tier (record it; do
not bury it).

---

## Status board

| # | Problem | Status | Blocking dependency | Milestone met? |
|---|---|---|---|---|
| 1 | Effectiveness measurement | OPEN | none | No |
| 2 | Trigger-precision measurement | OPEN | none | No |
| 3 | Staleness-detection automation | OPEN | expected-output convention (design decision, ungated as yet) | No |
| 4 | Transfer across model tiers | OPEN | Problem 1's task set and rubric | No |

Update this board — and the external-positioning consequences — the moment
any milestone is met or an experiment returns a null. A met milestone entry
must link to the run artifacts that reproduce it from this repo alone.

## When NOT to use this skill

- **You want to know whether a specific fact in a skill is still true** →
  use `skill-verification-toolkit` (prove-before-you-write commands and the
  structural validator).
- **You are doing routine upkeep of the library** (re-running Provenance
  checks, pruning, updating date stamps) → use `skill-library-maintenance`.
  This skill only covers *automating* that upkeep as a research problem.
- **You are about to make or gate a change to the library** → use
  `skill-library-change-control`.
- **You are running the adversarial review of the full set** → use
  `multi-agent-review-campaign`. Review checks internal quality; this skill
  is about *external* proof of effectiveness.
- **You need the SKILL.md format or description mechanics** → use
  `agent-skills-format-reference`. Problem 2 measures trigger behavior; the
  format reference documents the conventions being measured.
- **You are writing or wording a skill** → `skill-authoring-runbook` and
  `skill-writing-style`.

## Provenance and maintenance

All facts below verified 2026-07-06 in this working tree. Re-verify before
relying on any of them; each may drift.

| Claim | Re-verification one-liner |
|---|---|
| Repo's tracked history contains only README.md and LICENSE | `git -C . log --all --name-only --pretty=format: \| sort -u \| grep -v '^$'` |
| README.md targets Sonnet-class readers and says "Wrong runbooks are worse than none" | `grep -n -e 'Sonnet' -e 'Wrong runbooks' README.md` |
| No CI configuration exists in the repo | `ls -d .github 2>&1; grep -rl -i 'workflow\|\.gitlab-ci\|circleci' --include='*.yml' --include='*.yaml' . --exclude-dir=.git \|\| echo 'no CI files'` |
| Structural validator exists and is structure-only (no command execution) | `grep -c 'eval\|bash -c\|sh -c' .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh` (expect 0) |
| Library skill count referenced by Problem 2 | `ls -d .claude/skills/*/ \| wc -l` |
| `experiments/` files proposed in Problems 1–2 still do not exist (all four problems still OPEN) | `ls .claude/skills/skill-library-research-frontier/experiments 2>&1` (expect: No such file or directory — if it exists, update the Status board) |

Maintenance rules for this file: every entry stays labeled OPEN until its
falsifiable milestone is met and reproducible from this repo alone; nulls
and negative results get recorded with the same prominence as positives;
and no external claim of novelty or proof is permitted until the
corresponding board row reads "Yes" with linked, reproducible artifacts.
