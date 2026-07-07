---
name: agent-skills-format-reference
description: "Use when you need to know how Claude Code agent skills mechanically work before writing or reviewing one: the .claude/skills/<name>/SKILL.md directory layout, YAML frontmatter fields (name, description), how descriptions trigger skill loading, progressive disclosure into extra files, the scripts/ convention, relative-path discipline, and kebab-case naming. Load this for any question of the form 'what is the SKILL.md format', 'where do skills live', 'what goes in frontmatter', or 'why isn't my skill triggering'."
---

# Agent Skills Format Reference

This is the domain-theory pack for this project. The "domain" here is the
Claude Code agent-skills mechanism itself, because this repository's product
IS a skill library (see the repo's `README.md`, which is the project manifest
— the repo contains no application code; verified 2026-07-06, see Provenance).

Everything below describes **conventions of Claude Code as widely documented
as of 2026-07-06**. Claude Code is actively developed; anything about loader
behavior is marked `[verify against current Claude Code docs]` where it could
drift. Facts about *this repo* are stated only where verified.

**Jargon defined once:**

| Term | Meaning |
|---|---|
| **Skill** | A directory under `.claude/skills/` containing a `SKILL.md` that teaches a model (or human) how to do one class of task. |
| **Frontmatter** | The YAML block between `---` fences at the top of `SKILL.md`. It is metadata the loader reads *before* deciding to load the body. |
| **Trigger / triggering** | The moment the model decides a skill is relevant to the current task and loads its body. Driven by the `description` field. |
| **Progressive disclosure** | Keeping `SKILL.md` short and scannable, pushing long reference material into sibling files that are read only on demand. |
| **Loader** | The Claude Code machinery that discovers skills and surfaces their names/descriptions to the model. Its exact behavior is version-dependent. |

## When NOT to use this skill

| Your actual task | Use instead |
|---|---|
| Authoring a new skill end to end (process, phases, agent orchestration) | `skill-authoring-runbook` |
| Prose quality: voice, tables, checklist style, sentence-level rules | `skill-writing-style` |
| Proving a command/path/claim before writing it into a skill | `skill-verification-toolkit` |
| Deciding how the whole library is structured and why | `skill-library-architecture-contract` |
| Changing an existing skill (gating, review) | `skill-library-change-control` |
| Keeping skills true as things drift over time | `skill-library-maintenance` |

Load this skill for the **file format and loading mechanics only**. It does
not tell you what to write, only where it goes and how it gets found.

## 1. Directory layout

One skill = one directory = one `SKILL.md`:

```
<repo-root>/
  .claude/
    skills/
      <skill-name>/
        SKILL.md            # required; the skill itself
        <extra>.md          # optional; long reference material (progressive disclosure)
        scripts/            # optional; executable helpers shipped with the skill
          <helper>.sh
```

Rules:

- The file must be named exactly `SKILL.md` (uppercase). `[verify against
  current Claude Code docs]` for case-sensitivity guarantees, but uppercase
  `SKILL.md` is the universal convention — use it.
- `<skill-name>` is the directory name and must equal the frontmatter `name`
  field (Section 2).
- Skills under `<repo-root>/.claude/skills/` are **project skills**: they
  travel with the repo and load for anyone who clones it. Skills under
  `~/.claude/skills/` are **personal/global skills**: they belong to one
  user's machine. This library ships project skills only.
- Nothing outside the skill's own directory belongs to the skill. Do not
  scatter support files elsewhere in the repo.

List the library:

```sh
ls .claude/skills/
```

Sanity-check that every skill directory actually contains a SKILL.md:

```sh
for d in .claude/skills/*/; do [ -f "$d/SKILL.md" ] || echo "MISSING: $d"; done
```

## 2. YAML frontmatter

Minimum viable frontmatter is two fields:

```yaml
---
name: my-skill-name
description: "Use when <task vocabulary that should trigger loading> ..."
---
```

### `name`

- Must equal the directory name, exactly. A mismatch is a defect: tooling and
  humans both use the directory name as the identity, and a divergent `name`
  field creates two identities for one skill.
- kebab-case: lowercase, digits, hyphens. No spaces, no underscores, no
  capitals.

Check the whole library for name/directory mismatches:

```sh
for d in .claude/skills/*/; do
  n=$(sed -n 's/^name:[[:space:]]*//p' "$d/SKILL.md" | head -1)
  [ "$n" = "$(basename "$d")" ] || echo "MISMATCH: dir=$(basename "$d") name=$n"
done
```

### `description` — the trigger surface

This is the single most load-bearing line in the file. Mechanics
`[verify against current Claude Code docs]`, but the widely documented model is:

1. The loader surfaces skill **names and descriptions** to the model up front
   (cheap, always in context or indexed).
2. The **body** of `SKILL.md` is loaded **only after** the model decides,
   from the description, that the skill matches the current task.

Consequences you must design for:

- **The description carries retrieval keywords; the body carries the
  payload.** A brilliant body behind a vague description never loads. A
  keyword-rich description in front of an empty body loads and disappoints.
- Write the description in **task vocabulary** — the words a model or engineer
  would actually have in mind when they need this skill ("why isn't my skill
  triggering", "where do skills live"), not in author vocabulary ("this
  document describes...").
- Start with "Use when ..." and state the trigger conditions explicitly.
  This library's house rule (per the repo manifest and library conventions):
  at least 80 characters, trigger-rich.
- The description must also let a model **rule the skill out** cheaply. Name
  the boundary if the skill is easily confused with a sibling.

Anti-patterns:

| Bad description | Why it fails |
|---|---|
| `description: Skill format notes.` | No trigger words; never matches a task. |
| `description: Everything about skills.` | Matches everything; collides with every sibling; model can't choose. |
| A description that summarizes the body's *content* rather than the *situations* that call for it | Retrieval matches situations, not tables of contents. |

### Other frontmatter fields

Some Claude Code versions and plugins recognize additional frontmatter fields
(e.g., tool restrictions or model hints). Do not rely on any field beyond
`name` and `description` without checking: `[verify against current Claude
Code docs]`. This library uses only `name` and `description`.

## 3. Progressive disclosure

`SKILL.md` competes for context-window space with the actual task. Keep it
scannable; push bulk elsewhere.

- **Target:** `SKILL.md` holds the decision-relevant material — when-to-use,
  procedures, tables, checklists, the minimal example. Roughly 150–400 lines
  is this library's norm (guidance, not a loader limit).
- **Overflow:** long reference matter (exhaustive option catalogs, worked
  transcripts, large lookup tables) goes into additional `.md` files inside
  the same skill directory.
- **Reference overflow files relatively**, from the skill's own directory,
  and tell the reader when to open them:

```markdown
For the full option catalog, read [reference.md](reference.md) — only needed
when adding a new option.
```

- Every overflow file must be *pointed at* from `SKILL.md` with a one-line
  statement of when to read it. An unreferenced file in a skill directory is
  dead weight — nothing will ever load it.

## 4. The `scripts/` convention

Executable helpers that a skill teaches you to run should ship **inside the
skill's own `scripts/` subdirectory**, not be described as prose you retype.

- Path: `.claude/skills/<skill-name>/scripts/<helper>`.
- Make them runnable from the repo root and self-describing (`--help` or a
  header comment).
- `SKILL.md` shows the invocation as a copy-pasteable command using a
  **repo-relative** path:

```sh
bash .claude/skills/my-skill/scripts/check-something.sh
```

- A script is part of the skill: it is reviewed, verified, and change-
  controlled with the skill (see `skill-library-change-control`).

Verified fact about this repo: as of 2026-07-06 there is no application code
for scripts to operate on — the repo's tracked files are `README.md` and
`LICENSE` only — so any script shipped in this library operates on the skill
library itself (linting frontmatter, checking links, etc.).

## 5. Relative-path discipline

The library must survive a fresh `git clone` at **any** path on **any**
machine. Therefore:

- **Never** cite a user-specific absolute path (`/home/<user>/...`,
  `/Users/<name>/...`, `/tmp/...`) as a load-bearing source, target, or
  command argument in a skill.
- All paths in commands are relative to the repo root, and commands are
  written to be run from the repo root.
- If a command must be location-independent, anchor it explicitly:

```sh
cd "$(git rev-parse --show-toplevel)" && ls .claude/skills/
```

Scan the library for absolute-path leaks:

```sh
grep -rnE '/(home|Users)/[A-Za-z0-9._-]+' .claude/skills/ && echo "LEAKS FOUND" || echo "clean"
```

(Exception: a skill may *mention* an absolute path when explaining what not
to do — as this section does. The rule bans absolute paths as things the
reader is told to depend on.)

## 6. Naming conventions

- **kebab-case**, always: `repo-discovery-playbook`, not
  `RepoDiscoveryPlaybook` or `repo_discovery_playbook`.
- **Prefix to avoid collisions.** Project skills share a namespace with the
  user's personal/global skills and with plugin-provided skills. Generic
  names (`debugging`, `testing`, `style`) risk shadowing or confusion.
  Convention: prefix with the project or domain (this library uses
  `skill-library-*` and `skill-*` prefixes for its project-process skills;
  the repo manifest's own taxonomy uses `<project>-*`). Exact
  collision-resolution behavior between project, personal, and plugin skills
  is version-dependent: `[verify against current Claude Code docs]` — the
  robust move is to make collisions impossible by naming.
- Name for the **task**, not the artifact: `failure-archaeology-mining`
  (what you do) beats `git-history-notes` (what it contains).
- Names appear in trigger matching alongside descriptions, so a name that
  contains task vocabulary helps retrieval.

## 7. Minimal complete example

A smallest-correct skill, in full. Directory:
`.claude/skills/acme-log-triage/` (example name — not a skill in this repo).

```markdown
---
name: acme-log-triage
description: "Use when triaging errors in acme service logs: mapping an error signature to its owning subsystem, finding the first bad request, or deciding whether a log pattern is a known-benign noise line versus a real fault."
---

# Acme Log Triage

Map a log error to its subsystem and decide if it is real.

## When NOT to use this skill

Fixing the bug once located — use `acme-debugging-playbook` instead.

## Procedure

1. Extract the error signature:

   ```sh
   grep -oE 'ERR-[0-9]{4}' service.log | sort | uniq -c | sort -rn
   ```

2. Look up the signature in the ownership table below.

| Signature | Subsystem | Known-benign? |
|---|---|---|
| ERR-1001 | ingest | no |
| ERR-2044 | cache | yes — see [benign-noise.md](benign-noise.md) |

## Provenance and maintenance

- Verified against acme v3.2 logs, 2026-07-06.
- Re-verify the signature table: `grep -c ERR- docs/error-codes.md`
```

What makes it complete: frontmatter `name` matches the directory;
`description` is trigger-phrased ("Use when...") and rules the skill out for
the fixing task; body is imperative with a copy-pasteable command; overflow
(`benign-noise.md`) is referenced relatively with a when-to-read note; it
ends with dated provenance and a re-verification command.

## 8. Frontmatter checklist

Run this checklist on every new or edited skill before review:

- [ ] File is `.claude/skills/<name>/SKILL.md` — exact filename `SKILL.md`.
- [ ] Frontmatter is fenced by `---` on its own line, top of file, valid YAML.
- [ ] `name:` present, kebab-case, **identical to the directory name**.
- [ ] `description:` present, ≥ 80 characters, starts from the trigger
      ("Use when ..."), written in task vocabulary, quoted if it contains `:`.
- [ ] Description lets a model rule the skill **out** as well as in.
- [ ] No reliance on frontmatter fields beyond `name`/`description` unless
      verified against current Claude Code docs.
- [ ] Body contains a "When NOT to use this skill" section naming siblings.
- [ ] All paths in commands are repo-relative; no user-specific absolute paths
      as load-bearing references (Section 5 scan is clean).
- [ ] Any extra files in the skill directory are referenced from `SKILL.md`
      with a when-to-read line.
- [ ] Ends with a "Provenance and maintenance" section: date stamp plus
      one-line re-verification commands.

Mechanical checks in one block (run from repo root):

```sh
d=.claude/skills/<skill-name>
head -1 "$d/SKILL.md" | grep -qx -- --- || echo "no frontmatter fence"
n=$(sed -n 's/^name:[[:space:]]*//p' "$d/SKILL.md" | head -1)
[ "$n" = "$(basename "$d")" ] || echo "name/dir mismatch"
grep -q '^description:' "$d/SKILL.md" || echo "no description"
grep -q 'When NOT to use' "$d/SKILL.md" || echo "no when-not-to-use section"
grep -q 'Provenance and maintenance' "$d/SKILL.md" || echo "no provenance section"
```

## Provenance and maintenance

Date-stamped 2026-07-06.

Facts verified in this repo on 2026-07-06:

- Tracked files are `README.md` and `LICENSE` only; no application code.
  Re-verify: `git ls-files`
- Full history is 2 commits across all branches.
  Re-verify: `git log --oneline --all | wc -l`
- Skill directories present at authoring time.
  Re-verify: `ls .claude/skills/`

Version-dependent claims (all marked inline above) — re-verify against the
current Claude Code documentation at https://docs.anthropic.com/ (navigate to
Claude Code → skills) whenever Claude Code updates:

- Loader mechanics: descriptions surfaced first, body loaded on trigger.
- Recognized frontmatter fields beyond `name`/`description`.
- Collision behavior between project, personal (`~/.claude/skills/`), and
  plugin skills.
- Case-sensitivity of the `SKILL.md` filename.

Library-internal invariants — re-verify any time skills change:

- Every skill dir has a SKILL.md:
  `for d in .claude/skills/*/; do [ -f "$d/SKILL.md" ] || echo "MISSING: $d"; done`
- No name/dir mismatches: loop in Section 2.
- No absolute-path leaks: grep in Section 5.
