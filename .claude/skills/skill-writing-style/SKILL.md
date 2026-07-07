---
name: skill-writing-style
description: "Use when writing or editing prose inside any SKILL.md in this library — drafting a new skill, rewriting a section that reads as hedged or padded, fixing voice/tense, deciding between a table and prose, adding date-stamps to volatile facts, or checking a draft against house style before review. Contains the rule set with before/after examples, an anti-patterns table, and a copyable skeleton template."
---

# skill-writing-style: House style for skill prose

This skill is the writing standard for every SKILL.md in this library. It expands the
authoring rules that `README.md` (the project manifest, lines 41–48) states in one
paragraph: imperative runbook voice, copy-pasteable commands, jargon defined once,
tables and checklists, a "when NOT to use" section per skill, date-stamped volatile
facts, and a closing "Provenance and maintenance" section. Everything here either
paraphrases that manifest or is labeled as a house heuristic built on top of it.

**Definitions used throughout** (defined once, used consistently):

- **Skill**: a directory under `.claude/skills/` containing a `SKILL.md` with YAML
  frontmatter, loaded by a model when its `description` matches the task at hand.
- **Sibling skill**: another skill in this same library.
- **Volatile fact**: any claim that can silently become false as the repo changes
  (file counts, "X does not exist yet", inventories, tool versions).
- **Runbook voice**: second-person imperative instructions with explicit branches —
  the voice of a checklist an on-call engineer follows, not an essay.

## Who reads what you write

The audience is a zero-context mid-level engineer or a Sonnet-class model (per the
manifest). Assume they have never seen this repo, will copy-paste your commands
verbatim, and will take any confident sentence as fact. That dictates every rule
below: no hedging, no unverified claims, no undefined terms, no prose where a table
scans faster.

## The rules, with before/after examples

### Rule 1 — Imperative runbook voice

Give instructions as commands with explicit condition→action branches:
"Run X. If you see Y, do Z." Never narrate options ("one could consider..."),
never use passive voice for an action the reader must take, never hedge an
instruction you have verified.

| Before (reject) | After (accept) |
|---|---|
| "One could consider checking whether the file exists before proceeding." | "Check the file exists: `test -f SKILL.md \|\| echo MISSING`. If it prints `MISSING`, stop and create it first." |
| "It might be a good idea to perhaps verify the frontmatter." | "Verify the frontmatter parses (see skill-verification-toolkit for the command)." |
| "The description should ideally be updated by the author." | "Update the `description` field. Do not merge without it." |
| "Errors may possibly occur if the path is wrong." | "If the command errors with `No such file or directory`, the path is wrong — re-run discovery per repo-discovery-playbook." |

Genuine uncertainty is different from hedging. If a claim is unproven, say so
plainly and label it: "Heuristic, not verified:" or "Open problem — see
skill-library-research-frontier." Hedging disguises uncertainty; labeling exposes it.

### Rule 2 — Every command is copy-pasteable, with expected output

Every command lives in a fenced code block, runs from the repo root without
editing, and is followed by its expected output or output shape. A command whose
output the reader cannot predict is a trap: they cannot tell success from failure.

Before (reject):

> Use ripgrep to check for TODO markers in the skills.

After (accept):

```bash
rg -n 'TODO|FIXME' .claude/skills/ || echo "CLEAN"
```

Expected output: matching lines as `path:line:text`, or `CLEAN` if none.
(`rg` exits non-zero on zero matches, so the `|| echo` makes the empty case
visible instead of silent.)

Rules of thumb:

- One command per block when the reader must observe output between steps;
  chained commands only when intermediate output does not matter.
- Placeholders in angle brackets, explained immediately: `git log <skill-dir>`
  where `<skill-dir>` is the skill's directory path.
- If the expected output is long, show its shape ("one line per skill,
  `name<TAB>count`") rather than a fabricated transcript. Never invent literal
  output you did not observe — run the command in this repo first
  (skill-verification-toolkit owns the verification workflow).

### Rule 3 — Define each jargon term once, then use it consistently

Define a term at first use — one sentence, inline or in a definitions block —
then use exactly that term everywhere. Do not rotate synonyms ("skill" /
"module" / "playbook" for the same thing) and do not re-define mid-document.

| Before (reject) | After (accept) |
|---|---|
| "Check the frontmatter, then validate the header block, then fix the YAML preamble." (three names, one thing) | "Check the frontmatter (the YAML block between `---` fences at the top of SKILL.md). ... Fix the frontmatter." |
| "Run the CI." (undefined — and this repo has none) | "This repo has no CI config (verified absence, see Provenance). Run the check locally: ..." |

If a term is owned by a sibling skill (e.g., the SKILL.md loading mechanics),
define it in one line and link to the sibling for depth — do not re-teach it.

### Rule 4 — Tables for enumerable facts, prose for reasoning

If the content is a set of parallel facts (symptom→action, option→default,
before→after), use a table. If the content is an argument — why a rule exists,
how to weigh a trade-off — use short prose paragraphs. A wall of prose hiding an
enumerable list fails review; so does a table forced onto a nuanced argument.

Heuristic: if you catch yourself writing "First, ... Second, ... Third, ..."
with the same grammatical shape each time, it is a table or a list. If you catch
yourself putting multi-sentence reasoning inside a table cell, it is prose.

### Rule 5 — Checklists for gates

A **gate** is a point where the reader must confirm conditions before
proceeding (before publishing a skill, before claiming a fact, before merging).
Every gate is a Markdown checklist (`- [ ]`), each item independently checkable,
phrased so "checked" unambiguously means "safe to proceed". No item like
"- [ ] code is good" — only items with a binary test.

### Rule 6 — Every skill has a "When NOT to use this skill" section

Mandatory section in every SKILL.md. It names the specific sibling skill to load
instead for adjacent tasks — not just "this is out of scope". This is what stops
a model from loading three overlapping skills or the wrong one. See the skeleton
below for the shape, and this skill's own section for a live example.

### Rule 7 — Date-stamp volatile facts

Pattern: `(as of 2026-07-06)` appended to the claim, using the date you verified
it — never a relative phrase ("currently", "at the time of writing"), which
cannot be checked against anything.

| Before (reject) | After (accept) |
|---|---|
| "The repo currently has no test suite." | "The repo contains no test files or test-runner config (verified absence as of 2026-07-06; re-verify command in Provenance)." |
| "There are 12 skills at the moment." | "12 skill directories exist (as of 2026-07-06): `ls .claude/skills/ \| wc -l`." |

Every date-stamped fact must have a matching one-line re-verification command in
the Provenance section (Rule 8). A stamp without a re-check command is decoration.

### Rule 8 — End with "Provenance and maintenance"

The final section of every SKILL.md. It lists, for each claim that can drift, a
one-line command that re-proves it, plus the date of last verification. Format:
one bullet per claim, `claim — command`. What belongs there: verified absences,
counts, paths, sibling-skill names you reference. What does not: timeless
definitions and reasoning. (Who runs these and when is owned by
skill-library-maintenance; this rule only says the section must exist and be
executable.)

## Anti-patterns table

Reject a draft on sight for any of these:

| Anti-pattern | What it looks like | Fix |
|---|---|---|
| Hedged instruction | "You might want to consider running..." | State the command and the branch: "Run X. If Y, do Z." (Rule 1) |
| Unexplained abbreviation | "Check the FM before the PR" | Define at first use: "frontmatter (FM)" — or just don't abbreviate. (Rule 3) |
| Duplicated sibling fact | Re-explaining SKILL.md loading mechanics that agent-skills-format-reference owns | One home per fact: one-line summary + link to the sibling. |
| Motivational filler | "Documentation is the lifeblood of any great project!" | Delete. Every sentence must instruct, define, or prove. |
| Wall of prose for enumerable facts | Three paragraphs listing options one by one | Convert to a table. (Rule 4) |
| Padding a thin topic | Restating the same rule in three sections to hit a length target | Cut to the honest length. A short true skill beats a long padded one. |
| Command without expected output | Bare fenced block, reader can't tell success from failure | Add expected output or output shape. (Rule 2) |
| Invented specifics | Citing a test suite, CI config, or flag this repo does not have | Verify first (skill-verification-toolkit); phrase absences as verified absences. |
| Undated volatile fact | "There is currently no CI" | Add `(as of YYYY-MM-DD)` + re-verification command. (Rules 7–8) |
| Unlabeled speculation | Presenting a heuristic as established repo fact | Prefix with "Heuristic:" or route to skill-library-research-frontier. |

## Pre-submission style gate

Run this checklist on every draft before handing it to review
(multi-agent-review-campaign owns the review process itself):

- [ ] Frontmatter has `name` equal to the directory name and a `description` of 80+ characters phrased as "Use when ..." (format details: agent-skills-format-reference).
- [ ] Zero hedged instructions — search the draft: `rg -in 'might want|could consider|should ideally|perhaps|one could' <skill-dir>/SKILL.md` returns nothing, or only hits inside quoted before/after examples (this is a screen, not proof — read every hit, and read the prose the screen can't catch).
- [ ] Every fenced command was actually run in this repo, and its stated expected output matches what you observed.
- [ ] Every jargon term is defined exactly once at first use.
- [ ] No fact duplicated from a sibling — cross-reference instead.
- [ ] "When NOT to use this skill" section exists and names siblings by exact skill name.
- [ ] Every volatile fact carries `(as of YYYY-MM-DD)` and has a matching command in Provenance.
- [ ] "Provenance and maintenance" is the final section and every command in it runs cleanly from the repo root.
- [ ] Nothing overstated: unproven ideas are labeled heuristic/open, not fact.

## Skeleton SKILL.md template

Copy this into `.claude/skills/<skill-name>/SKILL.md` and replace every
`<placeholder>`. Delete comments (`<!-- ... -->`) before submitting.

````markdown
---
name: <skill-name>            # must equal the directory name
description: "Use when <specific task vocabulary a model would match on — name the
  actions, symptoms, and artifacts that should trigger loading this skill>. <What
  the skill contains, in one clause>."   # 80+ chars, trigger-rich
---

# <skill-name>: <one-line purpose>

<!-- 1–3 sentences: what this skill covers and for whom. No throat-clearing. -->

**Definitions**: <term> — <one-sentence definition>. <!-- only terms this skill introduces -->

## <First task-shaped section, e.g. "Procedure" or "Symptom → action">

<!-- Imperative steps. Each command in a fenced block with expected output: -->

```bash
<command runnable from repo root>
```

Expected output: <literal output you observed, or its shape>.
If instead you see <failure signal>, <branch action>.

## <Enumerable facts as a table>

| <key> | <value> | <caveat/date-stamp if volatile> |
|---|---|---|

## <Gate as a checklist, if this skill has one>

- [ ] <binary, independently checkable condition>

## When NOT to use this skill

- <adjacent task 1> — use <sibling-skill-name> instead.
- <adjacent task 2> — use <sibling-skill-name> instead.

## Provenance and maintenance

Last verified: <YYYY-MM-DD> against <what you checked>.

- <claim that may drift> — `<one-line re-verification command>`
- <claim that may drift> — `<one-line re-verification command>`
````

## When NOT to use this skill

- SKILL.md **mechanics** — frontmatter fields, loading/trigger behavior, directory
  layout, supporting files: use **agent-skills-format-reference**. This skill is
  about the prose inside the file, not the file format.
- Running the **end-to-end authoring pipeline** (discover → author → review):
  use **skill-authoring-runbook**. Style is one input to that pipeline.
- **Proving a claim true** before you write it (running commands, verifying
  absences): use **skill-verification-toolkit**. This skill tells you how to
  phrase the verified claim, not how to verify it.
- **Structural/architectural decisions** of the library (what skills exist, one
  home per fact as a design rule): use **skill-library-architecture-contract**.
- **Reviewing a finished library** adversarially: use **multi-agent-review-campaign**.
- **Gating and approving changes** to existing skills: use **skill-library-change-control**.
- **Keeping facts true over time** (re-running Provenance commands on a schedule):
  use **skill-library-maintenance**.

## Provenance and maintenance

Last verified: 2026-07-06, against the repo at commit `c321e16`.

- The manifest's authoring rules this style expands (voice, jargon, date-stamps, Provenance section) — `sed -n '41,48p' README.md`
- This repo contains only README.md and LICENSE outside `.claude/` and `.git/` — `ls -A | grep -v -e '^\.git$' -e '^\.claude$'` (expect exactly `LICENSE` and `README.md`)
- Repo history is 2 commits — `git log --oneline | wc -l` (expect `2`)
- Sibling skill names referenced here still exist — `ls .claude/skills/` (expect directories for: agent-skills-format-reference, skill-authoring-runbook, skill-verification-toolkit, skill-library-architecture-contract, multi-agent-review-campaign, skill-library-change-control, skill-library-maintenance, skill-library-research-frontier, repo-discovery-playbook)
- `rg` no-match exit behavior claimed in Rule 2 — `rg 'zzz_no_match_zzz' README.md; echo "exit=$?"` (expect `exit=1`)
