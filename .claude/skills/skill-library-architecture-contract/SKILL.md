---
name: skill-library-architecture-contract
description: "Use when deciding how a skill library should be structured: whether to add, merge, split, or delete a skill; where a fact should live; how to write a frontmatter description that actually triggers; or when you need the design rationale behind this library's 12-skill layout. Load before proposing any structural change to .claude/skills/, and when reviewing a library for duplication, dead skills, or padding."
---

# Skill Library Architecture Contract

This skill records the load-bearing design decisions of a skill library — the
invariants that must hold for the library to work for its consumers, WHY each
holds, and this library's own 12-skill layout as the worked instance. It also
states the known weak points plainly.

**Definitions used throughout (defined once, here):**

- **Skill**: a directory under `.claude/skills/` containing a `SKILL.md` file
  with YAML frontmatter (`name`, `description`) and a Markdown body. This is
  the standard Claude Code convention.
- **Frontmatter description**: the `description:` field. At runtime, a model
  sees only the name and description of every skill; it loads the full body
  only when the description matches the task at hand.
- **Sonnet-class consumer**: a smaller/cheaper model (or a zero-context
  mid-level engineer) that cannot be assumed to infer unstated intent. The
  library's target audience per this repo's README.md.
- **One home per fact**: the rule that every fact is stated authoritatively
  in exactly one skill; other skills link to it rather than restating it.
- **Substrate**: real repo content (code, configs, history) that a skill
  category would document. A category with no substrate here produces no skill.

**Repo context:** the repo tracks only `README.md` and `LICENSE` (see
`repo-discovery-playbook`'s discovery-result table — the single home for
the repo-context facts; verified 2026-07-06). README.md is the project
manifest — a specification for building `.claude/skills/` libraries — and
because there is no application code, "the project" this library documents
is the skill-library authoring practice that README.md defines. Every skill
in this library must stay honest about that.

---

## The five invariants

Violating any of these degrades the library for exactly the consumer it
exists to serve. They are ordered by how silently they fail.

| # | Invariant | One-line statement | Failure mode if violated |
|---|-----------|--------------------|--------------------------|
| 1 | One home per fact | Each fact lives in exactly one skill; siblings cross-reference | Copies drift apart; consumer cannot tell which is current |
| 2 | Trigger-rich descriptions | The description states exactly WHEN to load the skill, in task vocabulary | Skill is never loaded; it might as well not exist |
| 3 | Self-containedness | A loaded skill does its core job without loading siblings | Consumer follows half a runbook, or burns context loading the whole library |
| 4 | Taxonomy adaptation | Merge thin categories, split deep ones; never pad | Padded skills teach invented facts; hollow skills waste trigger slots |
| 5 | When-NOT-to-use routing | Every skill names the sibling to use instead | Consumer applies the wrong runbook confidently |

### Invariant 1 — One home per fact

Every fact (a command, a path, a rule, a historical event, a threshold) is
stated authoritatively in exactly one skill. When a sibling skill needs that
fact, it names the owning skill ("see `skill-library-change-control` for the
gating rules") instead of restating the content.

**Why.** Duplicated facts drift independently: one copy gets updated, the
other does not, and a Sonnet-class consumer has no way to tell which copy is
current — it will trust whichever it loaded. A single home makes staleness
detectable (one place to re-verify) and makes updates atomic (one edit).

**How to apply.** Before writing a fact, ask: "which skill's charter does
this fact belong to?" If the answer is a sibling, write a one-line pointer,
not the fact. Summarizing a sibling in one clause to justify the pointer is
fine; reproducing its tables, commands, or rules is a violation.

**Check.** There is no fully automated check; duplication detection is a
review task (see `multi-agent-review-campaign`, usability pass). A cheap
smell test — the same distinctive command or phrase appearing in multiple
skills:

```bash
# Example: find skills that restate the same distinctive string (run from the repo root)
grep -rl "your distinctive phrase here" .claude/skills/*/SKILL.md
```

### Invariant 2 — Trigger-rich descriptions

The frontmatter `description` must state exactly when a model should load
the skill, phrased in the vocabulary the model will actually encounter in
tasks ("Use when deciding whether to merge two skills…"), not in library
jargon ("Architectural guidance for taxonomies").

**Why.** The description is the skill's ONLY chance to be loaded. Skills are
matched against task context; the model sees descriptions, not bodies. A
vague or abstract description means the skill never fires — it is dead
weight that reads as coverage while providing none. This failure is silent:
nothing errors, the consumer simply proceeds without the knowledge.

**How to apply.** Write the description as a set of concrete trigger
situations, using the words a task would contain ("add a skill", "merge",
"where should this fact live", "description doesn't trigger"). House
guidance on phrasing lives in `skill-writing-style`; this contract only
mandates that triggers exist and are task-vocabulary.

**Check.**

```bash
# Descriptions that lack an explicit "Use when" trigger phrase (run from the repo root)
grep -L -i "use when" .claude/skills/*/SKILL.md
```

### Invariant 3 — Self-containedness

A skill, once loaded, must let the consumer complete that skill's core job
without loading any sibling. Cross-references (Invariant 1) are for
*adjacent* jobs and for facts owned elsewhere — never for steps on the
skill's own critical path.

**Why.** Two failure modes otherwise. (a) The consumer follows the runbook,
hits "now see skill X for the actual command", does not load X, and executes
half a procedure — worse than none. (b) The consumer defensively loads every
referenced sibling, blowing its context window, which defeats the point of
splitting the library into skills at all.

**Tension with Invariant 1, resolved.** One-home-per-fact governs *facts*;
self-containedness governs *procedures*. If a sibling-owned fact is on your
critical path, restructure so it is not (change the step boundary), or
accept that your skill's core job genuinely requires the sibling and say so
explicitly at the top ("this skill assumes you have run the pipeline in
`skill-authoring-runbook`"). An explicit stated dependency is acceptable; an
implicit mid-procedure one is not.

### Invariant 4 — Taxonomy adaptation

Start from the CORE + ADVANCED taxonomy in README.md (12 CORE categories,
4 ADVANCED — see README.md lines 9–39), then adapt: merge categories that
are thin for this project, split ones that are deep, add domain categories
the manifest did not imagine. README.md itself mandates this ("ADAPTED to
what Phase 1 found", "Aim for 10–16 skills").

**Why — and the key defect to avoid.** Padding a thin category into a
full-length skill is a defect, not completeness. A padded skill must invent
content to fill its length, and invented content violates the ground-truth
rule (README.md: "Wrong runbooks are worse than none"). For a Sonnet-class
consumer, a confident 300-line skill about configuration axes that do not
exist is actively harmful: it will be believed. When a category has no
substrate, the honest moves are: drop it (record the drop here), fold its
real fragment into a sibling, or write a deliberately short skill that says
why it is short.

**Check.** The worked-instance table below is the record of this library's
merges and drops. Any structural change must update it (routed through
`skill-library-change-control`).

### Invariant 5 — When-NOT-to-use routing

Every skill contains a "When NOT to use this skill" section that names
which sibling to use instead for the adjacent-but-different task.

**Why.** Trigger descriptions overlap at the edges; a consumer holding the
wrong skill has already committed context to it and will try to make it fit.
The negative section is the escape hatch: it converts "wrong skill loaded"
from a silent misapplication into a one-line redirect. It is also the
routing layer that lets Invariants 1 and 3 coexist — pointers need a
consistent place to live.

**Check.**

```bash
# Skills missing the mandatory negative-routing section (run from the repo root)
grep -L "When NOT to use" .claude/skills/*/SKILL.md
```

---

## Worked instance: this library's 12 skills

This library instantiates the README.md taxonomy under an unusual
constraint: the repo has no application code, so several README categories
have no substrate. The table maps every README category to its disposition.
Rows marked *(judgment)* are this library's adaptation calls, not README
mandates.

| README category (lines 9–39) | Disposition in this library | Why |
|---|---|---|
| change-control | `skill-library-change-control` | Direct instance: how library changes are classified, gated, reviewed |
| debugging-playbook | Folded into `skill-verification-toolkit` and `multi-agent-review-campaign` *(judgment)* | A doc-only library's failure modes are false claims and dead triggers; its "debugging" IS verification and adversarial review |
| failure-archaeology | `failure-archaeology-mining` | Reframed as method: with a 2-commit history there is no chronicle to write, so the skill teaches the mining technique itself |
| architecture-contract | `skill-library-architecture-contract` (this skill) | Direct instance |
| domain-reference | `agent-skills-format-reference` | The domain here is the SKILL.md format and its mechanics |
| config-and-flags | **Dropped — no substrate** | Verified: the repo has no configuration axes, no flags, no options. A skill here would be pure invention |
| build-and-env | **Dropped — no substrate** | Verified: no build system, no environment setup beyond `git clone`. Same reasoning |
| run-and-operate | `skill-authoring-runbook` | "Operating" this project means running the three-phase authoring pipeline end to end |
| diagnostics-and-tooling | `skill-verification-toolkit` | Measuring instead of eyeballing = ground-truth verification commands |
| validation-and-qa | Folded into `skill-verification-toolkit` | What counts as evidence for a claim is the same discipline as verifying it; one home |
| docs-and-writing | `skill-writing-style` | Direct instance: house style for skill prose |
| external-positioning | Folded into `skill-library-research-frontier` | With nothing shipped, positioning claims are all open problems — same home as the frontier |
| hardest-problem-campaign | `multi-agent-review-campaign` | The hardest live problem is proving the complete library correct; the executable campaign is the Phase-3 adversarial review |
| proof-and-analysis-toolkit | Folded into `skill-verification-toolkit` | "Prove it, don't just install it" here means prove-before-write; merged to keep one home for verification |
| research-frontier | `skill-library-research-frontier` | Direct instance: open problems in proving skill libraries work |
| research-methodology | Folded into `skill-library-research-frontier` *(judgment)* | The evidence bar for "this library works" is itself the frontier's open problem; too thin to stand alone without measurements to methodologize |

**Domain categories added** (README.md line 7 explicitly permits adding
categories the manifest did not imagine):

| Added skill | Why it exists |
|---|---|
| `repo-discovery-playbook` | Phase-1 discovery is a named phase of the practice this repo defines; it needs its own runbook |
| `owner-interview-protocol` | README.md Phase 1 caps owner questions at five; choosing them well is a distinct skill |
| `skill-library-maintenance` | README.md mandates date-stamped provenance and re-verification commands; the discipline of keeping a library true over time is its own job, distinct from authoring it |

Net: 16 README categories − 2 dropped − 5 folded + 3 added = 12 skills,
inside the README's mandated 10–16 range.

## Known weak points (stated plainly, per this skill's charter)

1. **No live codebase means no local worked examples.** The archaeology and
   discovery skills (`failure-archaeology-mining`, `repo-discovery-playbook`)
   teach methods that this repo's 2-commit, 2-file history cannot exercise.
   Their examples are either generic-tool behavior or synthetic. This is a
   structural limitation of the substrate, not fixable by writing more.
2. **Effectiveness on Sonnet-class models is unmeasured.** Every invariant
   above is rationale-backed but empirically unvalidated in this repo: no
   experiment has confirmed that these descriptions trigger correctly or
   that a Sonnet-class session performs better with this library than
   without. This is an open problem, owned by
   `skill-library-research-frontier` — do not restate it elsewhere as a
   solved property.
3. **Invariant 1 has no automated enforcement.** Duplication detection is
   manual/review-driven. Drift between skills can accumulate between review
   campaigns (mitigation lives in `skill-library-maintenance`).
4. **The folds are judgment calls.** The `debugging-playbook` and
   `research-methodology` folds especially (marked *(judgment)* above) could
   reasonably be unfolded if the project grows substrate for them. Treat
   the table as current state, not permanent law — changes route through
   `skill-library-change-control`.

## When NOT to use this skill

- **Writing or formatting an individual SKILL.md** (frontmatter fields,
  file layout, mechanics) → use `agent-skills-format-reference`.
- **Prose style, tone, tables-vs-text choices** → use `skill-writing-style`.
- **Actually running the authoring pipeline** (Phase 1→2→3 execution) → use
  `skill-authoring-runbook`; for Phase-1 specifics use
  `repo-discovery-playbook` and `owner-interview-protocol`.
- **Proposing, gating, or reviewing a specific change** to an existing skill
  → use `skill-library-change-control`. This skill tells you whether the
  *structure* should change; that one tells you *how* to land the change.
- **Verifying a specific claim/command before writing it** → use
  `skill-verification-toolkit`.
- **Checking whether the library still matches reality over time** → use
  `skill-library-maintenance`.
- **Reading about whether any of this measurably works** → use
  `skill-library-research-frontier`.

## Provenance and maintenance

All claims verified against the repo on **2026-07-06**. Re-verify before
trusting (run every command from the repo root, e.g. after
`cd "$(git rev-parse --show-toplevel)"`):

```bash
# Repo still contains only README.md and LICENSE (tracked files)
git ls-files | grep -v '^\.claude/'

# History still 2 commits, across all branches
git log --oneline --all -- README.md LICENSE

# README taxonomy lines still where this skill cites them (categories at lines 9-39, adaptation mandate at line 7)
sed -n '7p;9p;35p' README.md

# Library still has exactly the 12 skills listed above
ls .claude/skills/

# Every skill still satisfies Invariants 2 and 5 (empty output = pass)
grep -L -i "use when" .claude/skills/*/SKILL.md
grep -L "When NOT to use" .claude/skills/*/SKILL.md

# Every skill's frontmatter name still matches its directory name
for d in .claude/skills/*/; do
  n=$(sed -n 's/^name: *//p' "$d/SKILL.md" | head -1); b=$(basename "$d");
  [ "$n" = "$b" ] || echo "MISMATCH: $d has name '$n'";
done
```

Volatile facts in this skill: the 12-skill inventory and the
merge/drop table (drift whenever a skill is added, merged, split, or
removed — update the table in the same change, gated by
`skill-library-change-control`); the README line numbers cited above
(drift if README.md is ever edited).
