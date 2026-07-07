---
name: failure-archaeology-mining
description: Use when you need to reconstruct a repository's investigation history from git — finding reverts, deleted code, dead branches, churn hotspots, or the full life of a function — so nobody re-fights a settled battle. Load this before proposing a fix that may have been tried before, when writing a project failure-archaeology skill, or whenever a change touches code with a suspicious past.
---

# Failure archaeology: mining git history for dead ends, reverts, and stalled work

**Goal.** Turn raw git history into a chronicle of past investigations — what was tried, what failed, what was abandoned — written as *symptom → root cause → evidence → status*, so a future engineer or model never re-fights a settled battle.

**Jargon, defined once:**

| Term | Meaning |
|---|---|
| **Revert** | A commit that undoes an earlier commit. `git revert` writes a message starting `Revert "..."`, but humans also revert manually with arbitrary messages. |
| **Dead branch** | A branch containing commits never merged into the mainline. Its unmerged commits are stalled or abandoned work. |
| **Churn hotspot** | A file modified in unusually many commits — a proxy for instability, contention, or repeated failed fixes. |
| **Squash merge** | A merge that collapses a branch's commits into one, discarding the intermediate commits from mainline history. |
| **Force push** | Rewriting a remote branch's history (`git push --force`), erasing the old commits from that ref. |
| **sha** | A commit's hash identifier (e.g. `c321e16`). Cite these as evidence — they are the only durable pointers. |

**Scope note for this repo (verified 2026-07-06):** this repository's entire history is 2 commits touching only `README.md` and `LICENSE`, across all branches (repo context: see `repo-discovery-playbook`'s discovery-result table; expected shas are in the Provenance section below). There are no reverts, no deleted files, and no unmerged branch commits to mine. The recipes below are therefore general-purpose recipes with explained outputs, **not local case studies**. Run them verbatim in any repo you are excavating.

## When NOT to use this skill

- **You are doing first-contact orientation on an unfamiliar repo** (what is this, how does it build, where are the tests) → use `repo-discovery-playbook`. Archaeology is the deep-dive that *follows* discovery.
- **You need to verify a specific present-day claim** (does this flag exist, does this command run) → use `skill-verification-toolkit`.
- **You are deciding how to record a finding as a change to the skill library itself** → route through `skill-library-change-control`.
- **You want the owner's memory of past failures rather than git's** → use `owner-interview-protocol` (question 4 there covers costly past failures; git can't tell you about failures that never got committed).

## The recipe set

Each recipe gives: the command, what the output means, and — critically — **what conclusion it licenses**. Do not conclude more than the evidence supports.

### 1. Find reverts

```bash
git log --oneline -i --grep='revert'
```

- **Output:** one line per commit whose message contains "revert" (case-insensitive), as `<sha> <subject>`.
- **Meaning:** each hit is a candidate undo event. For a mechanical `git revert`, the subject is `Revert "<original subject>"` and the body names the reverted sha.
- **Licensed conclusion:** "a change matching this description was undone at this sha" — nothing more yet. To learn *why*, read the revert's full message and diff (recipe 6), then find the original commit and any re-attempt:

```bash
# Given a revert commit R: what did it undo, and was the idea retried later?
git show <R>                      # body usually cites the reverted sha
git log --oneline --all -S'<distinctive code from the reverted diff>'
```

- **Not licensed:** "this approach is impossible." A revert proves the approach failed *in that form at that time*. Check whether a later commit reintroduced it successfully before declaring it a dead end.
- **Miss risk:** manual reverts with messages like "back out flaky cache" or "undo #123" escape the grep. Widen with `-i --grep='back out' --grep='undo' --grep='roll ?back' -E` if the first pass looks implausibly clean.

### 2. Find deleted code and when it died

```bash
git log --diff-filter=D --summary
```

- **Output:** commits that deleted files, each followed by `delete mode 100644 <path>` lines.
- **Meaning:** every file the project ever removed, with the sha and date of removal.
- **Licensed conclusion:** "file X existed until commit Y." Read commit Y's message and diff to learn whether it was cleanup, a failed experiment being torn out, or a rename (a rename can appear as delete+add; confirm with `git log --follow -- <path>` or `git show <Y> --stat -M`).
- **Recover the corpse** when you need to read what was removed:

```bash
git show <Y>^:<path>        # the file's content in the parent of the deleting commit
```

- **Not licensed:** "this code was bad." Deletion motive lives in the message and surrounding commits, not in the deletion itself.

### 3. Trace a function's full life

Two complementary commands:

```bash
# Line-range/function history: every commit that touched this function, with diffs
git log -L :<funcname>:<path>
# or an explicit line range:
git log -L <start>,<end>:<path>
```

```bash
# "Pickaxe": every commit that changed the NUMBER of occurrences of a string, repo-wide
git log -S'<symbol>' --oneline --all
```

- **Output:** `-L` prints each touching commit with the function's diff at that point. `-S` prints commits where the symbol was added or removed (it skips commits that merely moved the symbol within a file; use `-G'<regex>'` to also catch moves and edits on matching lines).
- **Licensed conclusion:** the birth commit (first `-S` hit chronologically), every rework, and the death commit if the symbol vanished. This is how you answer "has anyone tried X before?" — search for the symbols X would require.
- **Trap:** `-L :funcname:` relies on git's language heuristics to find function boundaries; for unusual languages, fall back to explicit line ranges or `-G`.

### 4. Find dead branches and what stalled on them

```bash
git fetch --all --prune          # see the real remote state first
git branch -a --no-merged main   # branches with commits not in main
git log main..<branch> --oneline # exactly which commits are stranded there
```

- **Output:** `--no-merged` lists branches whose tips are not ancestors of `main` (substitute your mainline name — verify with `git branch -a` or `git symbolic-ref refs/remotes/origin/HEAD`). The `main..<branch>` range lists the commits on `<branch>` that main lacks.
- **Meaning:** each such branch is work that stopped before landing. The last commit's date (`git log -1 --format='%ci %s' <branch>`) tells you when it stalled; the stranded diffs (`git diff main...<branch>`) tell you what was being attempted.
- **Licensed conclusion:** "this line of work exists and did not merge." Whether it stalled because it failed, was superseded, or just lost priority requires reading the commits and any linked PR/issue. Record it as `open` or `superseded`, never silently `settled`.
- **Local demonstration (this repo):** `git branch -a --no-merged main` here returns nothing — the only non-main branch (`claude/github-repo-setup-rq6ccz`) points at the same commit as main (verified 2026-07-06). Empty output means "no stranded work", which is itself a recordable finding.

### 5. Find churn hotspots

```bash
git log --format= --name-only | sort | uniq -c | sort -rn | head
```

- **Output:** files ranked by how many commits touched them, e.g. `142 src/scheduler.c`. (`--format=` suppresses commit headers so only file paths stream out.)
- **Meaning:** the top entries are where the project's effort — and often its pain — concentrated.
- **Licensed conclusion:** "this file changed N times" — a *pointer*, not a verdict. High churn is consistent with instability, but also with a file that is simply central (a changelog, a config). Discriminate by reading the actual commits: `git log --oneline -- <path>` and look for fix/revert/retry language and clustered dates.
- **Refinement:** scope by time (`git log --since='6 months ago' ...`) or by author, and exclude noise paths: append `| grep -v -E '^(docs/|CHANGELOG)'` before the `sort`.

### 6. Read a fix in context

```bash
git show <sha>                                   # full message + diff of the fix
git log --oneline --graph -10 <sha>              # the 10 commits leading up to it
git log --oneline --all --ancestry-path <sha>..  # what happened AFTER it (follow-ups, reverts)
```

- **Output:** the commit itself, then its before-and-after neighborhood.
- **Meaning:** a fix's real story is rarely in one commit. The window before shows the failed attempts; the window after shows whether the fix held (silence) or didn't (follow-up fixes, a revert).
- **Licensed conclusion:** only after reading the window may you mark an investigation `settled`. A fix followed within days by another fix to the same file is an investigation that was *not* settled at that sha.

## The output format: how to write a finding

Every excavated investigation gets recorded in exactly this shape. One finding per battle. This format is the deliverable; the commands above are just how you fill it in.

```markdown
### <short battle name>
- **Symptom:** what was observed going wrong (user-visible behavior, failing test, bad number).
- **Root cause:** the mechanism, if established. Write "not established" if the history only shows the failure, not the diagnosis.
- **Evidence:** shas, file paths, branch names, PR/issue numbers. Every claim above must trace to one of these.
- **Status:** one of:
  - `settled` — root cause found, fix landed, no later contradiction in history.
  - `open` — problem observed, no landed resolution (includes stalled branches).
  - `superseded` — the whole approach was replaced; the old battle is moot but instructive.
```

Rules for findings:

- **Evidence is mandatory.** A finding with no sha is a rumor; delete it or go dig up the sha.
- **Status is a claim you must be able to defend.** `settled` requires you checked the after-window (recipe 6). When in doubt, `open`.
- **Negative findings count.** "Searched history for reverts/deletions touching the cache layer; none exist (commands: recipes 1–2, run 2026-07-06)" prevents the next person from repeating the dig.
- Where these findings live and how they get added to the library is `skill-library-change-control`'s territory; prose style is `skill-writing-style`'s.

## Traps: when the history lies to you

| Trap | What it hides | Mitigation |
|---|---|---|
| **Squash-merged repos** | All intermediate states of a branch — the failed attempts collapse into one clean commit. The archaeology-richest material is exactly what squashing deletes. | Check the hosting platform's PR history (per-PR commits often survive there even after squash); check `git log -g` (reflog) on a long-lived local clone; treat suspiciously clean history as *incomplete*, not as *no failures happened*. |
| **Force-pushed branches** | The pre-rewrite commits vanish from the remote ref. What you fetch is the sanitized version. | Old shas may survive in other clones, in PR references, or in the remote's reflog if you have server access. Absence of a sha you saw cited elsewhere is a force-push tell. |
| **Commit messages lie** | Messages describe intent, not effect. "Fix race condition" may fix nothing; "cleanup" may bury a behavior change. | **Trust diffs over messages, always.** Read `git show <sha>` before citing any commit as evidence. A message is a hypothesis about its own diff. |
| **Shallow clones** (`--depth N`) | Everything older than N commits. All the recipes silently return truncated results. | `git rev-parse --is-shallow-repository` — if `true`, run `git fetch --unshallow` before mining. |
| **Rename blindness** | `--diff-filter=D` and per-path logs lose the thread across renames. | Add `--follow` for single-path logs; add `-M` to `git show`/`git log --summary` to detect renames. |

## Provenance and maintenance

All facts about *this* repository below were verified on 2026-07-06 by running the stated commands at the repo root. General git behavior was spot-checked against git as installed in this environment; the recipes use long-stable porcelain and should not drift, but re-verify local facts before trusting them:

```bash
# History is still 2 commits touching only README.md and LICENSE:
git log --oneline --all            # expect: c321e16, c30ac04
git ls-files                       # expect: LICENSE, README.md
# Still no reverts anywhere in history:
git log --oneline -i --grep='revert'          # expect: empty
# Still no deleted files in history:
git log --diff-filter=D --summary             # expect: empty
# Still no stranded branch work:
git branch -a --no-merged main                # expect: empty
# Churn table still trivial:
git log --format= --name-only | sort | uniq -c | sort -rn | head   # expect: 2 README.md, 1 LICENSE
```

If any of these outputs change, this skill's "Scope note" is stale: the repo has acquired real history, and the recipes here should be re-run to produce actual local findings (recorded per the output format above, routed through `skill-library-change-control`).
