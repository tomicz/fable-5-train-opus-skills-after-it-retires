---
name: skill-authoring-runbook
description: >-
  Use when you are the orchestrator producing a .claude/skills/ library for a
  target repository end to end — planning phases, spawning parallel authoring
  agents, running the three-reviewer barrier, applying fixes, and delivering.
  Load this for tasks phrased like "build the skill library", "run the
  authoring pipeline", "orchestrate the skill authors", or "review and fix the
  skills". It is the operate runbook; it delegates each phase's depth to
  sibling skills.
---

# Skill-authoring runbook: the three-phase pipeline end to end

This is the orchestrator's runbook for turning a target repository into a
`.claude/skills/` library that a zero-context mid-level engineer or a
Sonnet-class model can use to carry the project forward. It sequences the
whole pipeline; sibling skills hold the depth for each step (see
cross-references throughout — one home per fact).

**Jargon, defined once:**

- **Skill** — a directory `.claude/skills/<name>/` containing a `SKILL.md`
  with YAML frontmatter (`name`, `description`) and a runbook-style body.
  Format details live in `agent-skills-format-reference`.
- **Orchestrator** — the top-level session (you) that runs discovery, spawns
  subagents, enforces barriers, and delivers. Subagents write; the
  orchestrator coordinates.
- **Authoring agent** — one subagent that writes exactly one skill.
- **Barrier** — a synchronization point: no later-phase work starts until
  every earlier-phase artifact exists on disk.
- **Findings note** — a plain-text summary of what Phase 1 discovery proved
  about the repo, with the commands that proved it. It is the shared input to
  every authoring prompt.
- **Ground-truth rule** — nothing goes into a skill as fact unless it was
  verified against the repo or is a clearly-labeled convention/heuristic.
  The enforcement toolkit is `skill-verification-toolkit`.

**Source of authority:** the target repo's own manifest. In this repository
that is `README.md`, which defines the three phases (its `## Phase 1`,
`## Phase 2`, `## Phase 3` headings), the authoring rules, and the
10–16-skill taxonomy. Repo context: the repo tracks only `README.md` and
`LICENSE` (see `repo-discovery-playbook`'s discovery-result table; verified
2026-07-06) — so here, "the project" the library documents is the
skill-library authoring practice itself. Every skill must stay honest about
that wherever it matters.

## Pipeline at a glance

| Phase | Actor(s) | Output | Gate to next phase |
|---|---|---|---|
| 1. Discover | Orchestrator (serial) | Findings note + owner answers | Findings note written; questions asked and answered (or timeout noted) |
| 2. Author | N parallel authoring agents | One `SKILL.md` per skill | ALL planned skill files exist on disk |
| 3. Review | 3 parallel reviewers, then 1 fixer | Findings lists; fixed library | Blocking + important findings applied |
| Delivery | Orchestrator | Validator pass + inventory report | Handoff per session branch instructions |

Token cost is not a constraint; correctness is (repo manifest, README.md
line 1). Prefer more verification over less.

---

## Phase 1 — Discover (no skill authoring yet)

Serial, orchestrator-only. Do not spawn authors until this phase is done.

### Steps

1. **Run discovery.** Follow `repo-discovery-playbook` in full: manifest and
   docs, build system, test suite, CI config, git history including dead
   branches and reverts, TODO/FIXME hotspots, data/deploy conventions.
   For the history-mining part specifically (reverts, stalled branches, dead
   ends), use `failure-archaeology-mining`.
2. **Write the findings note.** Put it in your scratchpad (never in the
   repo). For every claim, record the command that proved it. Include
   verified absences ("no CI config: `ls .github/workflows` → no such
   directory") — absences are facts too and authors will need them.
3. **Formulate at most five owner questions.** Follow
   `owner-interview-protocol`. Hard rule: only ask what the repo cannot
   tell you. If discovery already answered it, do not spend a question on it.
   The manifest's suggested five (README.md Phase 1): hardest live problem,
   unwritten discipline rules, audience and what it does NOT know, costliest
   past failures, and what "beyond state of the art" means here.
4. **Fold answers in.** Append owner answers to the findings note, marked
   `OWNER-STATED` so authors can attribute them ("per the project owner…")
   rather than presenting them as repo-verified fact. If the owner does not
   answer, record that and proceed — authors then label those areas open.

### Phase 1 exit checklist

- [ ] Findings note exists, every claim paired with its proving command
- [ ] Verified absences recorded explicitly
- [ ] ≤ 5 owner questions asked; answers (or non-answer) folded in
- [ ] Taxonomy adaptation drafted (next section) from findings, not from
      the template alone

---

## Phase 2 — Author (parallel agents, one skill per agent)

### Step 1: Adapt the taxonomy

Start from the manifest's 10–16-skill taxonomy and adapt it to what Phase 1
found: merge categories that are thin in this repo, split ones that are
deep, add domain categories the template missed. The rationale and the
resulting design decisions belong in — and should be reconciled with —
`skill-library-architecture-contract`. Fix the final skill-name list NOW:
every authoring prompt embeds the full sibling list, so the list must be
frozen before any agent launches.

### Step 2: Launch one agent per skill, in parallel

One skill per agent. Parallel is safe because write scopes are disjoint:
each agent writes only inside its own `.claude/skills/<skill-name>/`
directory.

**Every authoring prompt MUST embed all six of these** (an agent has zero
context beyond its prompt — anything you omit, it will invent):

| # | Mandatory element | Why |
|---|---|---|
| 1 | Audience statement | Zero-context mid-level engineer / Sonnet-class model; imperative runbook voice |
| 2 | Format rules | Frontmatter fields, trigger-rich description, required sections, line-count target — per `agent-skills-format-reference` |
| 3 | GROUND-TRUTH-ONLY rule | Verify before stating; verified absences for negatives; label heuristics as heuristics |
| 4 | Sibling list | Full frozen skill-name list with one-line scopes, for cross-references — one home per fact |
| 5 | Date stamp | Today's date, for the Provenance section |
| 6 | Write-scope restriction | Write only `.claude/skills/<own-name>/`; read anything; NO mutating git commands |

Also embed the findings note (or its load-bearing excerpts) and the
`OWNER-STATED` answers relevant to that skill.

### Authoring-agent prompt skeleton

```text
You are one of <N> parallel agents authoring a skill library at
<REPO>/.claude/skills/.

PHASE-1 FINDINGS (verified <DATE>):
<paste findings note: what the repo is, what exists, verified absences,
OWNER-STATED answers>

GROUND TRUTH RULES (violating these is the worst failure mode):
- State as fact only: (a) what the repo's own files say — read them first,
  quote/paraphrase accurately; (b) behavior of standard tools you are
  certain of — verify by running the command in the repo where practical;
  (c) widely-standard conventions, labeled as conventions.
- Never invent file paths, flags, test suites, CI configs, or history for
  this repo. Phrase negative claims as verified absences.
- Judgment-based guidance stays labeled guidance/heuristic. No oversell:
  open problems stay labeled open.

AUDIENCE: zero-context mid-level engineer or Sonnet-class model.
Imperative runbook voice. Copy-pasteable commands in fenced blocks. Define
every jargon term once. Tables and checklists. No filler.

FORMAT (mandatory):
- Write exactly one file: .claude/skills/<SKILL-NAME>/SKILL.md
  (plus files under that directory only if this brief says so).
- YAML frontmatter: name: <SKILL-NAME> (must equal directory name);
  description: trigger-rich, ≥80 chars, "Use when ..." in task vocabulary.
- Body must include a "When NOT to use this skill" section naming which
  sibling to use instead, and a final "Provenance and maintenance" section
  with one-line re-verification commands, date-stamped <DATE>.
- Typically 150–400 lines. Depth over padding.

SIBLING SKILLS (cross-reference; never duplicate their content):
<frozen list: name — one-line scope, for all N skills>

SCOPE: write ONLY inside your own skill directory. Never modify anything
else. Never run mutating git commands (no add/commit/push/checkout).
Read anything you like.

YOUR SKILL: <SKILL-NAME> — <one-line scope>
CONTENT BRIEF: <what this skill must cover, organized however reads best>

Write the file now, then return a one-paragraph summary and any caveats
(claims you could not verify).
```

### Phase 2 exit checklist (the barrier)

- [ ] Every planned `SKILL.md` exists — verify, do not trust agent reports:

```sh
ls -d .claude/skills/*/SKILL.md
```

- [ ] Count matches the frozen list; any missing skill is re-run before
      Phase 3 starts. **No reviewer launches until ALL skills exist** —
      reviewers check cross-skill consistency, which is meaningless against
      a partial set.
- [ ] Collect each agent's caveats; pass them to the FACTUAL reviewer.

---

## Phase 3 — Review and fix

Run the review per `multi-agent-review-campaign` — it IS the Phase-3
procedure, whether run inside this pipeline or as a standalone audit, and
it owns the reviewer briefs (FACTUAL / DOCTRINE / USABILITY), the severity
classes, the single-fixer rule, and fix scoping. Do not restate or adapt
those here; load that skill and follow it. This runbook only sequences the
phase:

- **Barrier in:** every planned `SKILL.md` exists on disk (Phase-2 exit
  checklist passed). Reviewers check cross-skill consistency, which is
  meaningless against a partial set.
- Launch the campaign over the COMPLETE set; hand the authoring agents'
  caveat lists to its FACTUAL reviewer.
- MINOR findings are not fixed in this phase: the campaign batches them
  for `skill-library-maintenance`.

### Phase 3 exit checklist

- [ ] Campaign completed through its promotion gate (validator re-run,
      spot-checks passed)
- [ ] All BLOCKING + IMPORTANT findings applied (or a reasoned skip
      recorded for each)
- [ ] Fixer's "new unverified claims" list is empty, or those claims were
      re-verified

---

## Delivery

1. **Run the validator** from `skill-verification-toolkit` over the whole
   library (frontmatter well-formed, `name` matches directory, required
   sections present, description length). Fix any failures before handoff.
2. **Report to the owner** (per the manifest's Phase 3 close): the skill
   inventory with one-line descriptions, what you verified by spot-check,
   and what remains uncertain.
3. **Run the gated commit step.** This is the commit step defined in
   `skill-library-change-control`: a human or the orchestrator — never an
   authoring, reviewer, or fixer agent — runs `git add` / `git commit` /
   push, only here at delivery, per the session's branch instructions. The
   no-mutating-git rule binds every agent throughout Phases 1–3; version
   control happens exclusively at this delivery step. If the session
   provides no branch instructions, ask the owner; do not guess a branch.
   Ongoing change management after delivery is
   `skill-library-change-control`.

## When NOT to use this skill

- **Authoring or fixing ONE skill** (you are a subagent, not the
  orchestrator): use `skill-writing-style` for prose,
  `agent-skills-format-reference` for format mechanics, and
  `skill-verification-toolkit` before stating any fact. This runbook is
  for the coordinator.
- **Doing Phase-1 discovery itself**: use `repo-discovery-playbook`
  (and `failure-archaeology-mining` for history mining). This skill only
  tells you where discovery sits in the pipeline.
- **Deciding which skills to have and why**: use
  `skill-library-architecture-contract`.
- **Writing the owner questions**: use `owner-interview-protocol`.
- **Running the Phase-3 review itself** — the reviewer briefs, severity
  classes, and fix scoping, whether inside this pipeline or as a
  standalone audit of an already-delivered library: use
  `multi-agent-review-campaign`. It owns the review procedure; this
  runbook only sequences the phases around it.
- **Post-delivery upkeep** (drift, re-verification cadence, edits over
  time): use `skill-library-maintenance` and
  `skill-library-change-control`.

## Provenance and maintenance

Date-stamped 2026-07-06. Facts here that can drift, and how to re-check
each in one line (run from the repo root):

- The three phases, the ≤5-question rule, the taxonomy, the authoring
  rules, and the reviewer/fixer design all come from the repo manifest:
  `grep -n "^## Phase" README.md` (expect Phases 1–3) and re-read
  README.md before re-running the pipeline — it is the source of
  authority and may change.
- "Repo contains only README.md and LICENSE plus `.claude/`":
  `git ls-files` (verified 2026-07-06: `LICENSE`, `README.md` tracked;
  `.claude/` is this pipeline's untracked output).
- "2-commit history, two branches": `git log --oneline | wc -l` and
  `git branch -a` (verified 2026-07-06: commits `c30ac04`, `c321e16`;
  branches `main` and `claude/github-repo-setup-rq6ccz`).
- Sibling skill names cited above:
  `ls .claude/skills/` (names must match; if the taxonomy changed, update
  the sibling list and the "When NOT to use" pointers here).
- The prompt skeletons are guidance distilled from the manifest's
  authoring rules, not verbatim repo text — treat them as templates to
  adapt, and re-check them against README.md's "AUTHORING RULES" section:
  `grep -n "AUTHORING RULES" README.md`.
