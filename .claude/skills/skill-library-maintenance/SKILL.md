---
name: skill-library-maintenance
description: Use when maintaining an existing .claude/skills/ library over time — re-verifying skills after a repo change, deciding whether a skill is stale, updating "as of" date stamps, deprecating a skill whose subject was removed, or diagnosing why models following the library keep failing. Also use when scheduling or running the quarterly maintenance pass.
---

# skill-library-maintenance — Keeping a skill library true over time

Skills rot because repos move. A skill that was verified true in January can send an
engineer down a wrong path in July after one directory restructure. This skill defines
the maintenance discipline: what to re-verify, when a re-verification pass is mandatory,
how to retire a dead skill, and how to diagnose a library that is failing its consumers.

**Definitions used below**

| Term | Meaning |
|---|---|
| Skill | A directory under `.claude/skills/<name>/` containing a `SKILL.md` (format details: see sibling `agent-skills-format-reference`) |
| Drift | The repo changed but a skill's claims did not; the skill is now partly false |
| Re-verification command | A one-line shell command whose output confirms (or refutes) a specific claim in a skill |
| Date stamp | An "as of YYYY-MM-DD" marker recording when a claim was last *verified*, not when it was written |
| Deprecation | The staged retirement of a skill whose subject no longer exists |

**Repo context:** see `repo-discovery-playbook`'s discovery-result table — the single
home for the repo-context facts (verified 2026-07-06). In one clause: no application
code, no CI, no tests — so in *this* repo, "the repo moved" means "README.md (the
manifest) changed" or "the skill library itself changed." The discipline below is
written to survive both this repo and repos with real code.

## 1. The Provenance-and-maintenance section contract

Every skill in this library ends with a section titled **"Provenance and maintenance"**.
This is a contract required by the project manifest (README.md line 46: *"end each skill
with a 'Provenance and maintenance' section containing one-line re-verification commands
for anything that may drift"*). The contract has three parts:

1. **Every volatile claim gets a one-line re-verification command.** Volatile = anything
   the repo could change: paths, file counts, commands, flags, quoted line numbers,
   negative claims ("no CI exists"). The command must be copy-pasteable and its expected
   output stated or obvious.
2. **A maintainer re-runs the commands, then edits or re-stamps.** If output matches the
   skill's claim, update the date stamp to today. If it does not match, fix the prose to
   match reality *first*, then re-stamp. Never re-stamp a claim you did not re-check.
3. **The section carries the verification date**, e.g. "verified 2026-07-06".

The maintainer loop, per skill:

```bash
# 1. Open the skill's Provenance section and run each listed command, e.g.:
sed -n '/## Provenance and maintenance/,$p' .claude/skills/<name>/SKILL.md

# 2. For each command: run it, compare output to the skill's claim.
# 3. Edit the skill body wherever reality diverged (through change control — see
#    sibling skill-library-change-control).
# 4. Update the date stamp(s) to today.
```

A skill whose Provenance commands all pass and whose date stamp is fresh is **green**.
A skill with a failing command is **stale** and must not be re-stamped until fixed.

## 2. Date-stamp semantics

"As of YYYY-MM-DD" means **verified on that date** — someone ran the check and the claim
held. It does not mean "written on that date."

Rules:

- **Re-stamp only after re-running the check.** A date stamp updated without re-running
  the command is a lie with a timestamp.
- **Stamp per claim-cluster, not per file, when freshness differs.** If you re-verified
  the paths but not the command outputs, stamp them separately or fix the gap.
- **An old date stamp is a signal, not a defect.** A skill stamped 6+ months ago is due
  for a pass; it is not automatically wrong. Do not "freshen" stamps to look maintained.
- **A missing date stamp on a volatile claim is a defect.** File it as a fix through
  change control.

Reading a stamp as a consumer: treat any claim stamped before the last major repo change
(see drift triggers below) as unverified until you re-run its Provenance command.

## 3. Drift triggers — when a re-verification pass is mandatory

A **re-verification pass** = running every skill's Provenance commands and fixing/
re-stamping. Do a *targeted* pass (only skills touching the changed area) or a *full*
pass depending on blast radius. These events mandate one:

| Trigger | Pass scope | Why |
|---|---|---|
| Build system change (new build tool, changed build commands) | Targeted: build/env/run skills | Copy-pasted commands break silently |
| CI config change (added, removed, or reworked pipelines) | Targeted: validation/change-control skills | "How changes are gated" claims go stale |
| Directory restructure (files moved/renamed) | **Full pass** | Paths are quoted everywhere; blast radius is unbounded |
| Major dependency bump (framework/toolchain major version) | Targeted: any skill quoting that dependency's behavior | Flags and outputs change across majors |
| Any revert touching a documented area | Targeted: skills documenting that area | The skill may now describe the reverted state — and the revert itself belongs in failure-archaeology (see sibling `failure-archaeology-mining`) |
| README.md / project manifest change (this repo's main drift source) | **Full pass** | The manifest is the spec every skill answers to |
| Skill added, renamed, or deleted in the library | Targeted: cross-reference check (Section 4 grep) | Sibling pointers dangle |

Detecting triggers when you arrive cold:

```bash
# What changed since the library's newest verification stamp? (substitute the date)
git log --oneline --stat --since=2026-07-06 -- . ':!.claude/skills'

# Any reverts in that window?
git log --oneline --grep='revert' -i --since=2026-07-06
```

(Both verified to run in this repo, 2026-07-06; the first currently returns nothing
because no non-skill file has changed since the library was authored.)

## 4. The deprecation path — retiring a skill whose subject was removed

A skill whose subject no longer exists (the feature was deleted, the tool replaced, the
practice abandoned) is **not deleted silently**. Silent deletion breaks sibling
cross-references and erases the knowledge that the subject *used to exist* — which is
exactly what a future engineer needs when they find residue of it. The path:

**Step 1 — Mark superseded.** Edit the skill (through change control) so that:
- The `description:` frontmatter starts with `SUPERSEDED:` and names the replacement
  (or states there is none).
- The body's first line states what happened, when, and where to go instead:
  > SUPERSEDED as of 2026-07-06: the X subsystem was removed in commit `<sha>`.
  > Use `<replacement-skill>` instead. Kept for one release for link stability.

**Step 2 — Keep it one release.** One release = one project release cycle; if the
project has no release cadence (this repo currently has none — verified 2026-07-06, no
tags: `git tag` returns empty), use one quarterly maintenance cycle as the substitute.
During this window, consumers who load it get redirected, not stranded.

**Step 3 — Check nothing still points at it.** Before deletion, grep the library for the
skill's name:

```bash
grep -rn "the-dead-skill-name" .claude/skills/ --include='SKILL.md'
```

Every hit outside the dead skill's own directory is a cross-reference that must be
rewritten first. Zero external hits = safe to delete.

**Step 4 — Delete through change control.** The deletion is a library change like any
other: see sibling `skill-library-change-control` for gating and review. Record the
deletion rationale in the change record so the removal itself is archaeologically
recoverable via `git log -- .claude/skills/the-dead-skill-name/`.

## 5. Symptom table — a library failing its consumers

When engineers or models using the library keep failing, the failure mode identifies the
defect class. Diagnose from the symptom, not from vibes:

| Symptom | Defect class | Fix |
|---|---|---|
| Model follows a skill and hits a missing path / failing command | **Stale content** — the repo moved | Re-verify that one skill: run its Provenance commands, fix prose, re-stamp |
| Model never loads an existing, relevant skill for a matching task | **Description trigger failure** — the frontmatter `description:` does not match task vocabulary | Rewrite the frontmatter description with the words a consumer would actually use ("Use when …"); format rules in sibling `agent-skills-format-reference` |
| Two skills give conflicting instructions for the same situation | **Duplication defect** — a fact has two homes and one drifted | Consolidate to one home (the skill that owns the topic), replace the other copy with a cross-reference; ownership map in sibling `skill-library-architecture-contract` |
| Model loads the right skill but misreads it (wrong step order, missed caveat) | **Style/scannability defect** | Restructure per sibling `skill-writing-style`: tables, numbered steps, caveats adjacent to the step they guard |
| Model loads too many skills / the wrong one wins | **Trigger overlap** — descriptions compete | Sharpen each description's "When NOT to use" boundary; every skill must name which sibling to use instead |
| Skill is correct but the consumer cannot execute it (missing tool, permission, context) | **Audience mismatch** | Add the missing prerequisite inline or lower the skill's assumed context; audience bar is defined in README.md line 42 |

Heuristic (guidance, not repo fact): treat two independent consumer failures on the same
skill as mandatory-fix, one failure as investigate. Whether skill libraries measurably
help consumers at all is an open problem — see sibling `skill-library-research-frontier`;
do not claim the library "works" from the absence of complaints.

## 6. Quarterly maintenance checklist

Run this every quarter, or immediately after any Section-3 trigger. Budget: one focused
session. Work through it top to bottom.

- [ ] **1. Diff the world.** `git log --oneline --stat --since=<last-pass-date>` — list
      every non-skill change; map each to the skills that document that area.
- [ ] **2. Check for reverts and dead branches** in the window (commands in Section 3);
      route findings to the failure-archaeology skill (sibling
      `failure-archaeology-mining` explains the mining method).
- [ ] **3. Run every skill's Provenance commands.** Track green / stale per skill:
      ```bash
      ls -d .claude/skills/*/
      ```
      gives the worklist (11 sibling skills expected alongside this one; count verified
      2026-07-06 in progress — the library was still being authored).
- [ ] **4. Fix stale skills** (prose first, stamp second), routing edits through change
      control (sibling `skill-library-change-control`).
- [ ] **5. Re-stamp every skill you actually re-verified.** No courtesy stamps.
- [ ] **6. Cross-reference integrity.** For each skill directory, list which sibling
      files mention it (incoming references), then confirm every skill-name mentioned in
      prose corresponds to a directory that still exists:
      ```bash
      cd "$(git rev-parse --show-toplevel)"
      for d in .claude/skills/*/; do n=$(basename "$d"); echo "== $n referenced by:"; \
        grep -rln "$n" .claude/skills/ --include='SKILL.md' | grep -v "/$n/"; done
      ```
      A skill with zero incoming references is an orphan-candidate (investigate, not
      auto-delete); a backticked skill name in prose with no matching directory is a
      dangling reference (fix immediately).
- [ ] **7. Frontmatter audit.** Every `SKILL.md` has `name:` equal to its directory and
      a `description:` that states when to load it:
      ```bash
      for f in .claude/skills/*/SKILL.md; do d=$(basename "$(dirname "$f")"); \
        grep -q "^name: $d$" "$f" || echo "NAME MISMATCH: $f"; done
      ```
- [ ] **8. Deprecation sweep.** Any skill marked SUPERSEDED for a full cycle: run the
      Section-4 grep and delete through change control if clean.
- [ ] **9. Symptom review.** Collect consumer failures since last pass; classify each
      with the Section-5 table; file fixes.
- [ ] **10. Record the pass.** Note the date and green/stale/fixed counts in the change
      record so the next maintainer knows when "since" starts.

## When NOT to use this skill

- **Authoring a new skill from scratch** → use `skill-authoring-runbook` (the three-phase
  pipeline); this skill only keeps existing skills true.
- **Verifying a claim before first writing it** → use `skill-verification-toolkit`; this
  skill covers *re*-verification of already-shipped claims.
- **Deciding whether an edit is allowed and how it is reviewed** → use
  `skill-library-change-control`; maintenance identifies the edits, change control gates
  them.
- **Running a one-time adversarial review of the whole library** → use
  `multi-agent-review-campaign`; the quarterly pass here is lighter-weight and recurring.
- **First contact with an unfamiliar repo** → use `repo-discovery-playbook`; maintenance
  assumes the library already exists and you know the repo.
- **Formatting questions about SKILL.md itself** → use `agent-skills-format-reference`.

## Provenance and maintenance

All claims verified 2026-07-06 against this repository. Re-verification one-liners
(run from the repo root — anchor with `cd "$(git rev-parse --show-toplevel)"` if unsure):

- Repo contains only README.md and LICENSE outside `.git`/`.claude`:
  `ls -A | grep -v -e '^\.git$' -e '^\.claude$'`
  (expect exactly `LICENSE` and `README.md`)
- History is 2 commits across all branches:
  `git log --oneline --all | wc -l` (expect `2`)
- No release tags exist: `git tag | wc -l` (expect `0`)
- Manifest still mandates the Provenance section and date stamps:
  `grep -n "Provenance and maintenance" README.md` (expect a hit on line 46)
- Manifest still defines the audience: `grep -n "Sonnet-class" README.md` (expect hits incl. line 42)
- Sibling skills named above still exist:
  `ls .claude/skills/` (expect directories for every sibling referenced in this file)
- Frontmatter name matches directory:
  `grep -c "^name: skill-library-maintenance$" .claude/skills/skill-library-maintenance/SKILL.md` (expect `1`)

If any command's output diverges, fix this skill's prose first, then re-stamp the date
above. Drift triggers that mandate a pass over this skill specifically: any README.md
change, any skill added/renamed/deleted in the library.
