#!/usr/bin/env bash
# Structural check for the AI workflow files: commands, skills, the guides they
# reference, and the entry files that list them.
#
#   bash .github/scripts/check-workflow.sh
#
# CI runs it on every PR (.github/workflows/workflow-check.yml); /init-project runs
# it in its integrity check. Prints one error per problem and exits 1 if any.
#
# Bash builtins only, on purpose: spawning processes is very slow in Git Bash on
# Windows, and this must stay quick to run locally there too (bash 3.2+).
set -uo pipefail
shopt -s nullglob
case "$0" in
  */*) cd "${0%/*}/../.." || exit 1 ;;
  *) cd ../.. || exit 1 ;;
esac

errors=0
fail() { echo "::error::$1"; errors=$((errors + 1)); }

# read_file <path> <var>: the file's content, with CRs stripped, into <var>.
read_file() {
  local _line _buf=""
  while IFS= read -r _line || [ -n "$_line" ]; do
    _buf+="${_line%$'\r'}"$'\n'
  done < "$1"
  printf -v "$2" '%s' "$_buf"
}

# frontmatter_name <path>: sets $fm_name to the frontmatter's `name:` value.
frontmatter_name() {
  local line first=1
  fm_name=""
  while IFS= read -r line; do
    line=${line%$'\r'}
    if [ "$first" = 1 ]; then
      first=0
      [ "$line" = "---" ] || return 0
      continue
    fi
    [ "$line" = "---" ] && return 0
    if [[ $line =~ ^name:[[:space:]]*(.*)$ ]]; then
      fm_name=${BASH_REMATCH[1]}
      return 0
    fi
  done < "$1"
}

# 1. Every command has a skill and delegates to it, every skill has a command,
#    and frontmatter names match the file/dir names.
for f in .claude/commands/*.md; do
  n=${f##*/}
  n=${n%.md}
  frontmatter_name "$f"
  [ "$fm_name" = "$n" ] || fail "$f: frontmatter name must be '$n'"
  if [ ! -f ".agents/skills/$n/SKILL.md" ]; then
    fail "$f has no matching .agents/skills/$n/SKILL.md"
  else
    read_file "$f" content
    [[ $content == *".agents/skills/$n/SKILL.md"* ]] || fail "$f must delegate to .agents/skills/$n/SKILL.md"
  fi
done
for d in .agents/skills/*/; do
  d=${d%/}
  n=${d##*/}
  if [ ! -f "$d/SKILL.md" ]; then
    fail "$d has no SKILL.md"
    continue
  fi
  frontmatter_name "$d/SKILL.md"
  [ "$fm_name" = "$n" ] || fail "$d/SKILL.md: frontmatter name must be '$n'"
  [ -f ".claude/commands/$n.md" ] || fail "$d has no matching .claude/commands/$n.md"
done

# 2. Every command is listed in the entry files and the workflow docs
#    (as `/name`, or as the `name` skill in AGENTS.md).
for doc in CLAUDE.md AGENTS.md .github/copilot-instructions.md workflow/README.md workflow/model-strategy.md; do
  if [ ! -f "$doc" ]; then
    fail "missing $doc"
    continue
  fi
  read_file "$doc" content
  for f in .claude/commands/*.md; do
    n=${f##*/}
    n=${n%.md}
    if [ "$doc" = AGENTS.md ]; then want="\`$n\`"; else want="\`/$n"; fi
    [[ $content == *"$want"* ]] || fail "$doc doesn't list the $n command"
  done
done

# 3. Every workflow/ or docs/ guide referenced from the workflow files exists.
ref_re='(^|[^A-Za-z0-9_./-])((workflow|docs)/[A-Za-z0-9_-]+\.md)'
for src in CLAUDE.md AGENTS.md .github/copilot-instructions.md .claude/commands/*.md .agents/skills/*/SKILL.md workflow/*.md docs/*.md; do
  [ -f "$src" ] || continue
  read_file "$src" rest
  while [[ $rest =~ $ref_re ]]; do
    ref=${BASH_REMATCH[2]}
    [ -f "$ref" ] || fail "$src references $ref, which does not exist"
    rest=${rest#*"${BASH_REMATCH[0]}"}
  done
done

# 4. .workflow-config names a supported tracker.
if [ ! -f .workflow-config ]; then
  fail "missing .workflow-config"
else
  tracker=""
  jira_project=""
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in
      issue_tracker=*) [ -n "$tracker" ] || tracker=${line#issue_tracker=} ;;
      jira_project=*) jira_project=${line#jira_project=} ;;
    esac
  done < .workflow-config
  case "$tracker" in
    github) ;;
    jira) [ -n "$jira_project" ] || fail ".workflow-config: issue_tracker=jira needs jira_project=<KEY>" ;;
    *) fail ".workflow-config must set issue_tracker=github or issue_tracker=jira" ;;
  esac
fi

if [ "$errors" -gt 0 ]; then
  echo "Workflow integrity: $errors problem(s) found."
  exit 1
fi
echo "Workflow integrity: OK."
