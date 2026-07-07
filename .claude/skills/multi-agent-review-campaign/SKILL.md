---
name: multi-agent-review-campaign
description: >-
  Use when a complete skill library must be adversarially reviewed before it
  can be trusted or committed — this is the Phase-3 review procedure of the
  README pipeline, and also the procedure for a standalone audit of an
  already-delivered library. Trigger phrases: "review the skill library",
  "run the three reviewers", "FACTUAL/DOCTRINE/USABILITY review", "verify the
  skills before commit", "the library is written, now check it". Covers the
  full decision-gated campaign: format preflight, three-reviewer fan-out over
  the COMPLETE set, verdict merge, scoped fixing, and the promotion gate into
  change control. Do NOT use while skills are still being authored (see
  skill-authoring-runbook) or for verifying a single claim (see
  skill-verification-toolkit).
---

# Multi-agent review campaign

## The problem this campaign solves

A freshly authored skill library is **plausible-looking but unproven**. This
campaign fills the hardest-problem slot of this library's taxonomy — treating
"prove the freshly authored library correct" as the hardest live problem is
ASSUMED (2026-07-06, owner unreachable; the owner's answer to README question 1
was never obtained — see `owner-interview-protocol`'s fallback protocol and the
taxonomy call in `skill-library-architecture-contract`). The reasoning: the
authors were capable models
writing fluent, confident prose, and fluent confident prose is exactly what
an invented command looks like. The consumers are junior engineers and
Sonnet-class models (smaller models that follow instructions literally and
do not second-guess a runbook). An error that a senior engineer would catch
and route around, a Sonnet-class consumer will execute. Therefore: **wrong
runbooks are worse than no runbooks** (README.md line 44: "Wrong runbooks
are worse than none"), and review is not optional polish — it is the step
that converts "written" into "trustworthy".

This campaign implements Phase 3 of README.md ("Three parallel reviewers
over the complete set, then one fixer") as a numbered, decision-gated
procedure. **Decision-gated** means: every phase ends with an expected
observation and an explicit branch instruction — "if you see X instead,
go to Y". Do not skip gates. Do not proceed on a failed gate.

Jargon used below, defined once:

| Term | Meaning |
|---|---|
| **Finding** | One reviewer-reported defect: (skill, claim/location, what is wrong, evidence, severity). |
| **Invented** | A claim with no supporting evidence in the repo (the command was never run, the path does not exist, the history event never happened). |
| **Stale** | A claim that repo evidence actively contradicts (it may once have been true). |
| **Blocking** | A finding that would send a consumer down a wrong path if followed literally. |
| **Fan-out** | Launching multiple agents in parallel on the same input with different briefs. |
| **Promotion** | The library moving from "under review" to "committable via change control". |

## Prerequisite: the complete set

This campaign runs over the **complete** library — every skill directory
under `.claude/skills/` — never over skills one at a time. Cross-skill
contradictions (two skills giving conflicting rules) and duplication (the
same fact maintained in two places, guaranteed to drift apart) are **only
visible over the complete set**. If authoring is still in progress, stop
and use `skill-authoring-runbook` instead; come back when every planned
skill exists.

```bash
# Confirm the set is complete: list skills, compare against the plan of record.
ls -1 .claude/skills/
```

Expected: one directory per planned skill (README.md targets 10–16). If
directories are missing → authoring is not done; do not start this campaign.

---

## Phase 0 — Preflight: format gate

**Purpose:** content reviewers must not burn effort on format defects. A
reviewer who spends their attention on "description is 60 characters"
findings is a reviewer not re-running commands. Format is machine-checkable;
check it by machine, first.

```bash
# From the repo root. Validator ships with the sibling skill-verification-toolkit.
bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh .claude/skills
```

The validator checks each `SKILL.md` for: frontmatter present, `name:`
equal to the directory name, `description:` of at least 80 characters, a
"Provenance" heading, and a "When NOT to use" heading.

**Expected observation:** `PASS <skill>` for every skill; exit code 0.

**Branch instructions:**

| Observation | Action |
|---|---|
| All PASS | Proceed to Phase 1. |
| Any FAIL | Fix the format defects (or send them back to the authoring agent), re-run the validator, and only proceed on all-PASS. Content review does not start until format is clean. |
| Validator script missing | The sibling skill was not authored or was renamed. Verify with `ls .claude/skills/skill-verification-toolkit/scripts/`. Do not hand-wave the gate; either restore the script or check the same five properties manually before proceeding. |

## Phase 1 — Fan-out: three parallel reviewers

Launch three reviewer agents **in parallel**, each over the **complete**
set, each with exactly one lens. One lens per reviewer is deliberate: a
reviewer asked to check everything checks nothing deeply. All three
reviewers are read-only — no reviewer edits any file.

Every finding a reviewer returns must carry: skill name, exact claim or
location (quote the line), what is wrong, the evidence (command run + its
output, or README.md line), and a proposed severity.

### Reviewer A — FACTUAL

**Brief:** re-run **every command in every skill** against this repo. Check
every path, flag, and history claim against reality.

- A claim is **invented** if no repo evidence supports it.
- A claim is **stale** if repo evidence contradicts it.
- The severity question for each finding: *would this send an engineer
  down a wrong path?* A command that errors loudly is important; a command
  that silently succeeds while doing the wrong thing is blocking.

Useful sweeps (heuristics, not a substitute for actually running the
commands each skill states):

```bash
# Extract every fenced command block for systematic re-execution:
awk '/^```/{f=!f; next} f' .claude/skills/*/SKILL.md

# Every path-shaped token a skill mentions — check each exists:
grep -rhoE '(\.\/|\.claude/|scripts/)[A-Za-z0-9_./-]+' .claude/skills/*/SKILL.md | sort -u

# Ground truth about this repo's real inventory and history:
git ls-files
git log --oneline --all
```

Note the trap specific to this repo: it contains **only** `README.md`,
`LICENSE`, and `.claude/skills/` (verified absence of anything else — see
`git ls-files`). Any skill that casually references this repo's "test
suite", "CI config", or "application code" as existing things is stating
an invented fact; the FACTUAL reviewer flags it.

### Reviewer B — DOCTRINE

**Brief:** the project's manifest is README.md; no skill may contradict it
and no skill may contradict another skill.

- Grep each skill's rules against README.md **verbatim** — when a skill
  quotes or paraphrases the manifest, open README.md and confirm the
  manifest actually says that:

```bash
# Find every skill line that invokes the manifest, then check each against the source:
grep -rn "README" .claude/skills/*/SKILL.md
sed -n '41,48p' README.md   # the authoring rules block, for fast comparison
```

- Flag **contradictions between skills**: two skills prescribing different
  procedures for the same situation, or one skill's "always" against
  another's "never". This is why review runs over the complete set.
- Flag **any behavior-changing instruction that skips gating**: README.md
  line 47 says "no skill may route around its change-control". A skill
  that tells the reader to commit, edit outside `.claude/skills/`, or
  promote unverified content without the change-control route is a
  doctrine violation regardless of how sensible it sounds.
- Flag overstated claims: anything unproven presented as established
  (README.md: "unproven things stay labeled open/candidate").

### Reviewer C — USABILITY

**Brief:** the library is only useful if it gets loaded and can be followed
without external context.

- For each skill, ask the trigger question: **given only the frontmatter
  `description`, would a model facing the target task load this skill?**
  If the description is generic ("helpful guidance about X") rather than
  task-vocabulary ("Use when you need to ..."), that is a finding.
- Flag **duplicated facts**: one home per fact; every other skill
  cross-references that home. Duplicated facts drift independently and
  one copy will eventually be wrong.
- Flag **non-self-contained sections**: steps that assume context the
  reader does not have ("as configured earlier", references to private
  paths, undefined jargon).
- Flag overlapping trigger descriptions: two skills whose descriptions
  would both fire on the same task confuse skill selection.

### Gate 1 — expected yield

**Expected observation:** a 10–16 skill library, freshly authored by
parallel agents with no shared memory, **typically yields findings on first
review** — cross-skill duplication and description overlap are near-certain,
and at least some factual drift is normal.

**Branch instructions:**

| Observation | Action |
|---|---|
| Findings returned by at least one reviewer | Proceed to Phase 2. |
| **All three reviewers return zero findings** | **Treat this as reviewer failure, not library cleanliness.** Re-run the fan-out with adversarial framing: "Assume at least one error per skill exists. Find it. Returning zero findings is itself a finding against you." Do NOT conclude the library is clean from a zero-finding first pass. |
| Second adversarial pass also returns zero | Now record it honestly as "two passes found nothing" — still not "proven clean" (that remains an open problem; see skill-library-research-frontier), but reviewed. Proceed to Phase 4 (nothing to fix). |
| A reviewer returns findings without evidence | Bounce them back: a finding without a re-runnable command or a README.md line citation is an opinion, not a finding. |

## Phase 2 — Verdict merge

One merger (can be the orchestrator) consolidates the three reports.

1. **Deduplicate by (skill, claim).** Two reviewers flagging the same line
   is one finding — note the double-flag, since independent detection is a
   confidence signal, but fix it once.
2. **Classify each finding:**

| Class | Definition | Handling |
|---|---|---|
| **Blocking** | Following it literally sends the consumer down a wrong path: invented command, stale path, doctrine violation, gating bypass. | Fixed now (Phase 3). |
| **Important** | Misleads or degrades trust without immediate wrong action: overstated claim, cross-skill contradiction on a non-procedural point, trigger description that fails the load test. | Fixed now (Phase 3). |
| **Minor** | Style, scannability, mild redundancy. | **Batched for maintenance** — recorded and handed to the skill-library-maintenance process, not fixed in this campaign. |

3. Produce a single ordered fix list: blocking first, then important, each
   with its evidence attached.

**Expected observation:** a deduplicated list where every entry names one
skill, one claim, one class, one piece of evidence.

**Branch:** if two reviewers *disagree* about a claim (FACTUAL says stale,
DOCTRINE says fine), re-verify it directly against the repo before merging —
the repo, not the louder reviewer, is the arbiter.

## Phase 3 — Fix: one fixer, scoped exactly to the list

One fixer agent applies **blocking + important findings only**. The scope
rule is absolute:

- The fixer edits only the lines the findings identify. No rewording of
  neighboring prose, no "while I'm here" improvements.
- **Each factual fix must include its re-verification command in the
  commit trail** — the exact one-line command that proves the corrected
  claim is now true. The natural home for these is also the skill's own
  "Provenance and maintenance" section, so future maintenance can re-check
  the same fact.
- Minor findings are untouched (they are in the maintenance batch).
- If a fix would require contradicting README.md or restructuring the
  library, the fixer stops and escalates — that is a design decision, not
  a fix (see skill-library-architecture-contract).

**Expected observation:** a diff that maps one-to-one onto the fix list.

**Branch:** if the diff touches anything not on the list → revert the
out-of-scope hunks before proceeding. See the fence below for why.

## Phase 4 — Promotion gate

Fixes are themselves fresh, unreviewed writing. Before the library is
promoted:

1. **Re-run the validator** (a fix can break format):

```bash
bash .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh .claude/skills
```

Expected: all PASS. Any FAIL → back to Phase 3 with the FAIL lines as the
new (blocking) fix list.

2. **Spot-check three random fixed claims.** Pick three entries from the
   applied fix list at random (roll, don't choose — chosen samples flatter
   the fixer) and re-run each one's re-verification command yourself.

Expected: all three hold. Any spot-check failure → the fixer's work is not
trustworthy as a batch; re-verify **every** applied fix, not just the failed
one, before continuing.

3. **Only then** does the library go through change control for commit.
   This campaign does not commit anything — commit classification, gating,
   and the actual git operations are owned by `skill-library-change-control`.
   Promotion without that route is itself a doctrine violation (README.md
   line 47).

## Known wrong paths — fenced off

Each of these would destroy the value of a review. They are reasoned fences,
not incidents from this repo — no such incident history exists here (the repo
has a 2-commit history with no reverts; see `skill-library-change-control`'s
honesty note). Do not discover them the hard way.

| Wrong path | Why it fails |
|---|---|
| **Letting the fixer "improve" skills beyond the findings** | Scope creep destroys review provenance: after the campaign you can no longer say "every line was either reviewed or is a traceable fix". Improved-but-unreviewed prose is exactly the plausible-looking, unproven material the campaign exists to eliminate. |
| **Reviewing skills one-by-one as they are authored** | Cross-skill contradictions and duplicated facts are only visible over the complete set. Per-skill review passes each skill individually while the library as a whole disagrees with itself. |
| **Judging quality by eye or by word count** | Fluency and length are what capable authoring models produce for free; they carry zero evidence. The only quality signals this campaign accepts are: commands that run, claims that match the repo, rules that match README.md, and descriptions that pass the load test. README.md's campaign standard is explicit: "success must be measurable, never judged by eye". |
| **Accepting a zero-finding first pass as clean** | See Gate 1. A reviewer that finds nothing in a fresh 10+ skill library has, on priors, failed to look — re-run adversarially before believing it. |

## When NOT to use this skill

- **Authoring is still in progress** → use `skill-authoring-runbook` (the
  three-phase pipeline; this campaign is its Phase 3, and it must not
  start early).
- **You need to verify one specific claim or command** → use
  `skill-verification-toolkit` (per-claim proof techniques; this campaign
  orchestrates reviewers who apply that toolkit at scale).
- **You are deciding whether/how to commit reviewed changes** → use
  `skill-library-change-control` (this campaign ends by handing off to it).
- **Ongoing drift-checking of an already-reviewed library** → use
  `skill-library-maintenance` (that is where the minor-findings batch goes).
- **You want to know whether review actually guarantees the library
  works for consumers** → open problem; see `skill-library-research-frontier`.

## Provenance and maintenance

Facts in this skill and how to re-verify them. Date-stamped 2026-07-06.

| Claim | Re-verification command |
|---|---|
| README.md Phase 3 defines three reviewers (FACTUAL/DOCTRINE/USABILITY) + one fixer | `sed -n '50,54p' README.md` |
| README.md: "Wrong runbooks are worse than none" | `grep -n "worse than none" README.md` |
| README.md: no skill may route around change-control; "never judged by eye" | `grep -n "route around\|judged by eye" README.md` |
| Validator exists at the sibling path and checks the five properties listed | `head -20 .claude/skills/skill-verification-toolkit/scripts/validate_skills.sh` |
| Repo contains only README.md, LICENSE, and .claude/skills/ (verified absence of code/CI/tests) | `git ls-files \| grep -v '^\.claude/skills/'` |
| Repo history is 2 commits | `git log --oneline --all \| wc -l` |
| Sibling skills named in this file exist | `ls -1 .claude/skills/` |

Heuristics in this file that are guidance, not repo fact (labeled so here
once, in case a future editor is tempted to harden them): the expected-yield
prior at Gate 1, the three-random-spot-checks sample size, the
blocking/important/minor boundaries, and the wrong-path fence table (reasoned
predictions, not incidents from this repo). Adjust them with judgment; record
changes through change control.

- ASSUMED (2026-07-06, owner unreachable): that proving the freshly authored
  library correct is this project's hardest live problem. README.md assigns
  that question to the owner (Phase-1 question 1); no owner answer exists, so
  this is the library's own judgment call per `owner-interview-protocol`'s
  fallback. Do not upgrade to fact without an actual owner statement.
