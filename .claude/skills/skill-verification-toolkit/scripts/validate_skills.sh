#!/usr/bin/env bash
# validate_skills.sh — structural validator for a .claude/skills/ library.
#
# Checks every <skills-dir>/*/SKILL.md for:
#   1. YAML frontmatter block present (opening '---' on line 1, closing '---' after it)
#   2. name: field present and equal to the skill's directory name
#   3. description: field present and at least 80 characters long
#      (folded/multi-line YAML scalars are concatenated before measuring)
#   4. a 'Provenance' section heading
#   5. a 'When NOT to use' section heading
#
# Usage:
#   scripts/validate_skills.sh [skills-dir]     # default: .claude/skills
#
# Output: one "PASS <skill>" or "FAIL <skill>: <reasons>" line per skill,
# then a summary. Exit 0 if all pass, 1 on any failure, 2 on bad invocation.
#
# Dependencies: POSIX shell utilities (sed, awk, basename) + grep. No bashisms
# beyond the shebang; runs under dash/sh as well.

SKILLS_DIR="${1:-.claude/skills}"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "ERROR: skills directory not found: $SKILLS_DIR" >&2
  echo "Usage: $0 [skills-dir]" >&2
  exit 2
fi

fail_count=0
pass_count=0
found_any=0

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  found_any=1
  name=$(basename "$dir")
  file="${dir}SKILL.md"
  errors=""

  if [ ! -f "$file" ]; then
    echo "FAIL $name: missing SKILL.md"
    fail_count=$((fail_count + 1))
    continue
  fi

  # --- Check 1: frontmatter block ---------------------------------------
  fm=""
  first_line=$(sed -n '1p' "$file")
  if [ "$first_line" != "---" ]; then
    errors="$errors; no frontmatter ('---' is not line 1)"
  elif ! sed -n '2,$p' "$file" | grep -q '^---$'; then
    errors="$errors; frontmatter never closed (no second '---' line)"
  else
    # Frontmatter body = lines between the first '---' and the next '---'.
    fm=$(sed -n '2,$p' "$file" | sed -n '/^---$/q;p')
  fi

  # --- Check 2: name: matches directory name ----------------------------
  fm_name=$(printf '%s\n' "$fm" | sed -n 's/^name:[ 	]*//p' | sed -n '1p' \
            | sed 's/^["'\'']//; s/["'\'']$//; s/[ 	]*$//')
  if [ -z "$fm_name" ]; then
    errors="$errors; missing name: field"
  elif [ "$fm_name" != "$name" ]; then
    errors="$errors; name '$fm_name' does not match directory '$name'"
  fi

  # --- Check 3: description: at least 80 characters ----------------------
  # Concatenate the description: line with any following indented
  # continuation lines (handles plain, quoted, and '>-' folded scalars).
  desc=$(printf '%s\n' "$fm" | awk '
    /^description:/ { in_d = 1; sub(/^description:[ \t]*/, ""); buf = $0; next }
    in_d && /^[ \t]/ { line = $0; sub(/^[ \t]+/, "", line); buf = buf " " line; next }
    in_d { in_d = 0 }
    END { print buf }')
  # Strip YAML block-scalar markers and surrounding quotes before measuring.
  desc=$(printf '%s' "$desc" | sed 's/^[>|][+-]\{0,1\}[ 	]*//; s/^["'\'']//; s/["'\'']$//')
  if ! printf '%s\n' "$fm" | grep -q '^description:'; then
    errors="$errors; missing description: field"
  elif [ "${#desc}" -lt 80 ]; then
    errors="$errors; description is ${#desc} chars (< 80)"
  fi

  # --- Check 4: Provenance section ---------------------------------------
  if ! grep -qi '^#\{1,6\} .*provenance' "$file"; then
    errors="$errors; no 'Provenance' section heading"
  fi

  # --- Check 5: 'When NOT to use' section --------------------------------
  if ! grep -qi '^#\{1,6\} .*when not to use' "$file"; then
    errors="$errors; no 'When NOT to use' section heading"
  fi

  # --- Verdict ------------------------------------------------------------
  if [ -z "$errors" ]; then
    echo "PASS $name"
    pass_count=$((pass_count + 1))
  else
    # Trim the leading '; '.
    errors=$(printf '%s' "$errors" | sed 's/^; //')
    echo "FAIL $name: $errors"
    fail_count=$((fail_count + 1))
  fi
done

if [ "$found_any" -eq 0 ]; then
  echo "ERROR: no skill directories under $SKILLS_DIR" >&2
  exit 2
fi

echo "----"
echo "checked: $((pass_count + fail_count))  pass: $pass_count  fail: $fail_count"

[ "$fail_count" -eq 0 ] || exit 1
exit 0
