---
name: owner-interview-protocol
description: Use when Phase-1 repo discovery is finished and you must ask the project owner questions before authoring skills — to spend the at-most-five question budget, prove each question is unanswerable from the repo, route each answer to the skill that consumes it, and follow the fallback protocol when the owner never replies.
---

# Owner interview protocol: spending five questions well

**Owner** = the human who commissioned the skill library and holds knowledge that never got written down (live priorities, unwritten rules, painful history). **Discovery** = the Phase-1 repo investigation defined in this repo's `README.md` and covered by the sibling skill `repo-discovery-playbook`. This skill governs the single step between them: the interview.

The project manifest (`README.md`, line 4) is explicit: after discovery, *"ask me AT MOST five questions, only for what the repo cannot tell you."* Five is a hard cap, not a target. Three well-proven questions beat five padded ones.

## The legitimacy test: every question carries its failed search

A question is legitimate **only if the repository cannot answer it**. The burden of proof is on you, and the proof is a search you actually ran that came back empty or ambiguous. Attach that proof to the question itself.

Required format for each question you submit:

```
Q<n>: <the question, one sentence>
Searched: <exact command(s) run>
Found instead: <what came back — empty, or the near-miss that does not answer it>
Consumed by: <which skill in the library needs this answer>
```

Why the failed search is mandatory:

| Without it | With it |
|---|---|
| Owner answers things the repo already says; budget wasted | Owner sees you did the homework and answers the real gap |
| You cannot tell "I didn't look" from "it isn't there" | The negative claim is verified, per the ground-truth rule |
| Reviewers cannot audit the question later | The search is replayable by anyone |

Run the search before writing the question, not after. If the search finds an answer, delete the question and use the budget elsewhere. (How to run rigorous searches and phrase verified absences is `skill-verification-toolkit`'s territory; this skill only requires that you attach the result.)

**Worked example from this repo** (an illegitimate question caught by the test):

```
Draft Q: "Who is the audience for this library?"
Searched: rg -in "audience" README.md
Found instead: README.md line 42 — "Audience: zero-context mid-level engineer
               or Sonnet-class model."
Verdict: PARTIALLY ANSWERED. The repo names the audience class. Only the
         second half — "what do they NOT know" — survives as a question.
```

## The five canonical questions

`README.md` line 4 lists five *likely* questions. They are canonical here because each one feeds a specific skill that cannot be written at full strength without it. Adapt the wording to what discovery found; keep the intent.

| # | Question (README paraphrase) | Why the repo cannot answer it | Consumed by |
|---|---|---|---|
| 1 | What is the hardest live problem right now? | "Live" priority is in the owner's head; git history shows past activity, not present pain | The hardest-problem campaign skill (in this library: `multi-agent-review-campaign`, per the campaign slot in the taxonomy) |
| 2 | What unwritten discipline rules exist — things you must not do that no doc states? | By definition unwritten; no search can find them, only their absence | `skill-library-change-control` (each rule becomes a gated non-negotiable) |
| 3 | Who is the audience, and what do they NOT know? | Docs state what the audience should learn, never what they currently lack | Every skill's assumed baseline — calibrates jargon definitions, step granularity, and what may be left unsaid |
| 4 | Which past failures cost the most time? | History shows *what* changed, not what it *cost*; reverts without context look identical whether they wasted an hour or a quarter | `failure-archaeology-mining` and any debugging content (each answer becomes a chronicled trap with its story) |
| 5 | What does "beyond state of the art" mean for this project? | Ambition is a value judgment; no artifact encodes it | `skill-library-research-frontier` (defines what counts as an open problem worth listing) |

Notes on using the table:

- Question 3 is the highest-leverage answer per word: it changes the register of *all* skills, not one. If you must cut to fewer than five, keep 3.
- Question 2 answers are the most dangerous to lose: an unwritten rule you never learn is a rule your successors will break. If the owner answers nothing else, chase this one.
- If discovery surfaced a repo-specific gap more urgent than one of the five (e.g., an unexplained mass revert), it may displace a canonical question — but it must pass the same legitimacy test and name its consuming skill.

## How to ask

1. Batch all questions into **one message**. Serial questions burn the owner's attention and invite scope drift.
2. Order by consequence-of-no-answer: the question whose absence damages the library most goes first, so a partial reply still covers it.
3. Use the four-line format above for every question. No preamble beyond one sentence of discovery summary.
4. State the fallback explicitly in the message: "If I don't hear back by <date>, I will proceed with assumptions marked ASSUMED and list these questions in the delivery report."

## Folding answers in

An answer that lives only in the chat transcript is lost knowledge. Route each answer to its consuming skill **as provenance, not paraphrase-only**:

1. Apply the answer to the skill's body (rules, thresholds, examples).
2. In that skill's **Provenance and maintenance** section, quote the owner verbatim with the date:

```markdown
- Owner (2026-07-06): "Never regenerate the golden set without a sign-off." —
  basis for the gating rule in section 3.
```

3. If an answer contradicts something the repo says, the contradiction goes to `skill-library-change-control` for resolution — do not silently pick a side.

One home per fact: the quote lives in the consuming skill; other skills cross-reference it.

## Fallback protocol: owner unreachable

This is not hypothetical. During this library's own authoring (2026-07-06), the interview step was skipped and the owner's answers were unavailable; the library was authored under this fallback. When the owner does not reply by your stated deadline:

1. **Proceed with the most defensible interpretation.** "Defensible" = the reading best supported by the repo's own text. For this library that meant: the repo contains only `README.md` and `LICENSE` (verified absence — see Provenance), so "the project" is the skill-library authoring practice the README defines, and the library documents that practice.
2. **Mark every assumption `ASSUMED`** in the Provenance section of each affected skill, with the reasoning:

```markdown
- ASSUMED (2026-07-06, owner unreachable): audience gap taken to be
  "no prior exposure to this repo or to skill-library authoring" — the most
  conservative reading of README.md line 42.
```

3. **List the unanswered questions in the delivery report** (the Phase-3 wrap-up to the owner), in the same four-line format, so the owner can answer asynchronously and corrections can be applied per `skill-library-change-control`.
4. Do **not** upgrade an ASSUMED item to fact later without an actual owner statement or repo evidence. Removing the marker is a change-controlled edit.

## Checklist before sending the interview

- [ ] Discovery complete (`repo-discovery-playbook` finished, findings written down)
- [ ] Five or fewer questions
- [ ] Every question has its failed search attached (command + what came back)
- [ ] Every question names its consuming skill
- [ ] Questions ordered by consequence-of-no-answer
- [ ] Fallback deadline stated in the message
- [ ] No question the repo already answers (re-run each search once, cold)

## When NOT to use this skill

- **Discovery is not finished** → use `repo-discovery-playbook` first. Questions asked before discovery cannot pass the legitimacy test, because you have not run the searches yet.
- **You want to verify a claim against the repo** → use `skill-verification-toolkit`. The interview is only for what verification proves *absent*.
- **You are deciding how to phrase or structure the answer inside a skill** → use `skill-writing-style` (prose) or `agent-skills-format-reference` (file mechanics).
- **The owner already answered and you are applying a correction** → use `skill-library-change-control`; the interview budget is spent once, before authoring.
- **You are reviewing an existing library rather than authoring one** → use `multi-agent-review-campaign`; reviewers re-verify, they do not re-interview.

## Provenance and maintenance

Date-stamped 2026-07-06. Facts here that can drift, and how to re-check each (commands run from the repo root):

- The at-most-five budget and the five canonical questions come from `README.md` line 4. Re-verify: `rg -n "AT MOST five" README.md` (expect a hit on the Phase-1 paragraph listing questions 1–5).
- The README's own audience statement (worked example): `rg -in "audience" README.md` (expect line 42, "zero-context mid-level engineer or Sonnet-class model").
- Verified absence (2026-07-06): the repo's tracked content is only `README.md` and `LICENSE`, across all branches and its 2-commit history. Re-verify: `git log --oneline --all` (expect 2 commits) and `git ls-tree -r --name-only main` (expect `LICENSE` and `README.md`; the `.claude/skills/` tree appears only once the library itself is committed).
- FACT (2026-07-06): this library was authored without owner answers; the fallback protocol above was the actual path taken. Unanswered questions belong in the delivery report — re-check the report before assuming any owner input exists.
- ASSUMED (2026-07-06, owner unreachable): the mapping "question 1 → hardest-problem campaign skill" points at `multi-agent-review-campaign` because that is the campaign-slot skill in this library's taxonomy; if the library's skill set changes, re-map by checking sibling directory names: `ls .claude/skills/`.
- The four-line question format and the ordering heuristic are guidance (this skill's judgment), not README requirements.
