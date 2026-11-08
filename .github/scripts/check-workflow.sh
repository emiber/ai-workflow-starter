#!/usr/bin/env bash
# Structural check for the AI workflow files: commands, skills, the guides they
# reference, and the entry files that list them.
#
#   bash .github/scripts/check-workflow.sh
#
# CI runs it on every PR (.github/workflows/workflow-check.yml); /init-project runs
# it in its integrity check. Prints one error per problem and exits 1 if any.
#
# Projects created from the starter keep this check on purpose: a command you add
# needs its playbook in .agents/skills/ and a line in the entry files, like the
# built-in ones, and a guide you reference must exist.
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

# Skill frontmatter: check_skill checks only the two required fields, in a small
# single-line subset of YAML. Passing it doesn't prove the frontmatter is valid
# YAML or a valid Agent Skills skill, and optional fields aren't checked.
#   - The first line is `---`, and the next `---` line closes the frontmatter;
#     text in the Markdown body after it doesn't count.
#   - Exactly one unindented `name:` and one unindented `description:`, in either
#     order. Other lines (optional fields, indented/nested keys, blank lines,
#     comment lines) are ignored, except an indented line that continues a
#     required field's value (no unindented line in between): that fails.
#   - Each is followed by a space or tab and a one-line value, with only spaces
#     or tabs around it: plain text that starts with an ASCII letter, has no
#     ": " or " #", doesn't end with ":" and isn't true/false/null (any case);
#     or text in '...' with no ' inside; or text in "..." with no " or \ inside.
#   - `name` equals the skill's directory name exactly; `description` isn't blank.
# Not supported, so rewrite them as one line of text in one of the forms above:
# block scalars (| or >), values continued on later lines, escapes, tags,
# anchors, aliases, lists, maps, and comments after a required field.
ws=$' \t'
letters=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz

# field_value <path> <field> <text after the colon>: sets $value to the field's
# text, or reports why it isn't in the supported form and returns 1.
field_value() {
  local v=$3 q why=""
  value=""
  while [[ $v == [$ws]* ]]; do v=${v#?}; done
  while [[ $v == *[$ws] ]]; do v=${v%?}; done
  if [ -z "$v" ]; then
    why="is empty"
  elif [[ $3 != [$ws]* ]]; then
    why="needs a space or tab after the colon"
  else
    case "$v" in
      \"* | \'*)
        q=${v:0:1}
        if [[ $v != ?*"$q" ]]; then
          why="has an unclosed quote or text after the closing quote"
        else
          v=${v#?}
          v=${v%?}
          if [[ $v == *"$q"* ]] || { [ "$q" = '"' ] && [[ $v == *'\'* ]]; }; then
            why="has its own quote or a backslash inside the quotes"
          elif [[ $v != *[!$ws]* ]]; then
            why="is empty"
          fi
        fi
        ;;
      [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee] | [Nn][Uu][Ll][Ll])
        why="needs quotes (YAML reads bare true, false and null as non-text)" ;;
      *:[$ws]* | *: | *[$ws]#*)
        why="can't have ': ' or ' #' or end with ':' unless quoted" ;;
      [$letters]*) ;;
      *) why="needs quotes" ;;
    esac
  fi
  if [ -n "$why" ]; then
    fail "$1: frontmatter $2: $why; write it as one line of text, plain (starting with a letter) or in '...' or \"...\" quotes"
    return 1
  fi
  value=$v
}

# check_skill <SKILL.md path> <skill name>: reports every problem in the skill's
# required frontmatter fields (see above).
check_skill() {
  local line rest cont="" opened=0 closed=0 names=0 descs=0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    if [ "$opened" = 0 ]; then
      [ "$line" = "---" ] || break
      opened=1
    elif [ "$line" = "---" ]; then
      closed=1
      break
    else
      case "$line" in
        name:*)
          names=$((names + 1))
          cont=""
          if field_value "$1" name "${line#name:}"; then
            cont=name
            [ "$value" = "$2" ] || fail "$1: frontmatter name must be '$2'"
          fi
          ;;
        description:*)
          descs=$((descs + 1))
          cont=""
          field_value "$1" description "${line#description:}" && cont=description
          ;;
        [$ws]*)
          # An indented line right after an accepted required field, other than
          # a blank or comment line, continues its value: report it once.
          if [ -n "$cont" ]; then
            rest=$line
            while [[ $rest == [$ws]* ]]; do rest=${rest#?}; done
            if [ -n "$rest" ] && [ "${rest:0:1}" != "#" ]; then
              fail "$1: frontmatter $cont: continues on the next line; write it as one line of text, plain (starting with a letter) or in '...' or \"...\" quotes"
              cont=""
            fi
          fi
          ;;
        "") ;;
        *) cont="" ;;
      esac
    fi
  done < "$1"
  if [ "$opened" = 0 ]; then
    fail "$1: frontmatter must start with a '---' line"
    return
  fi
  [ "$closed" = 1 ] || fail "$1: frontmatter has no closing '---' line"
  [ "$names" = 1 ] || fail "$1: frontmatter must have exactly one name: field, found $names"
  [ "$descs" = 1 ] || fail "$1: frontmatter must have exactly one description: field, found $descs"
}

# 1. Every command has a skill and delegates to it, every skill has a command,
#    and every skill's frontmatter passes check_skill. Command frontmatter isn't
#    checked: Claude Code ignores `name` on commands.
for f in .claude/commands/*.md; do
  n=${f##*/}
  n=${n%.md}
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
  check_skill "$d/SKILL.md" "$n"
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
