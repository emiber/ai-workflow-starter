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

# 2. Every command is listed in the entry files and the workflow docs: as
#    `/name` followed by a backtick or a space (`/name` or `/name <args>`), or
#    as the `name` skill in AGENTS.md. A longer command that starts with the
#    name, such as `/name-more`, doesn't count.
for doc in CLAUDE.md AGENTS.md .github/copilot-instructions.md workflow/README.md workflow/model-strategy.md; do
  if [ ! -f "$doc" ]; then
    fail "missing $doc"
    continue
  fi
  read_file "$doc" content
  for f in .claude/commands/*.md; do
    n=${f##*/}
    n=${n%.md}
    # AGENTS.md keeps the exact match, so alt is the same pattern as want.
    if [ "$doc" = AGENTS.md ]; then want="\`$n\`"; alt=$want; else want="\`/$n\`" alt="\`/$n "; fi
    [[ $content == *"$want"* || $content == *"$alt"* ]] || fail "$doc doesn't list the $n command"
  done
done

# 3. Every workflow/ or docs/ guide referenced from the workflow files exists.
#    Sources: the entry files, commands and skills, plus every visible *.md file
#    under workflow/ and docs/ at any depth. The walk skips hidden entries and
#    never enters or reads a symlink, so it can't loop.
#    A reference is a whole path (workflow|docs)/(NAME/)*NAME.md, optionally
#    followed by #FRAGMENT, where NAME is ASCII letters, digits, _ and -, and
#    FRAGMENT is the same characters or nothing. Prose punctuation around it is
#    fine, including a sentence-final ., ..., : or ?, and so are backticks and
#    Markdown such as [text](...). The path is resolved from
#    the repository root and must be a regular file with no symlink anywhere in
#    it; the fragment isn't checked. This scans raw text (code blocks included);
#    it isn't a Markdown or link checker.
#    Not references, so not checked at all: paths inside a larger path or URL
#    (other/docs/x.md, https://host/docs/x.md, ?next=docs/x.md, docs/x.md.bak,
#    docs/x.md/child, docs/x.md?raw=1), source-relative (../x.md) or absolute
#    paths, backslashes, ., .. or empty components, names with spaces, dots or
#    other characters, encoded names, .MD, queries, and other fragments.
#    Also not checked: a path glued to one of = & % ~ + : @ on either side
#    (key=docs/x.md, --file=docs/x.md, @docs/x.md, ~~docs/x.md~~, docs/x.md:12,
#    docs/x.md&a=1). They share one class with the URL characters because a
#    query value (?next=docs/x.md) can't be told apart from key=docs/x.md
#    without parsing the URL.
other='[^A-Za-z0-9_./\?#=&%~+:@-]' # a character that can't continue a path or URL
ref_re='(^|'"$other"')((workflow|docs)/([A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+\.md)(#[A-Za-z0-9_-]*)?($|'"$other"'|(\.+|[:?])($|'"$other"'))'

# check_refs <source>: reports every reference in <source> that isn't a regular
# file reached without symlinks.
check_refs() {
  local rest ref part left
  if [ ! -r "$1" ]; then
    fail "$1 isn't readable, so its guide references can't be checked"
    return
  fi
  read_file "$1" rest
  while [[ $rest =~ $ref_re ]]; do
    ref=${BASH_REMATCH[2]}
    rest=${rest#*"${BASH_REMATCH[0]}"}
    part=${ref%%/*}
    left=${ref#*/}
    until [ -L "$part" ] || [ "$part" = "$ref" ]; do
      part+=/${left%%/*}
      left=${left#*/}
    done
    if [ -L "$part" ]; then
      fail "$1 references $ref, but $part is a symlink; symlinked guide paths aren't supported"
    elif [ ! -f "$ref" ]; then
      fail "$1 references $ref, which does not exist"
    fi
  done
}

# check_guides <dir>: runs check_refs on every visible *.md file in <dir> and
# its visible subdirectories. Symlinks are skipped, never followed.
check_guides() {
  local e
  if [ ! -r "$1" ] || [ ! -x "$1" ]; then
    fail "$1 isn't readable, so the guides in it can't be checked"
    return
  fi
  for e in "$1"/*; do
    if [ -L "$e" ]; then
      continue
    elif [ -d "$e" ]; then
      check_guides "$e"
    elif [[ $e == *.md ]] && [ -f "$e" ]; then
      check_refs "$e"
    fi
  done
}

for src in CLAUDE.md AGENTS.md .github/copilot-instructions.md .claude/commands/*.md .agents/skills/*/SKILL.md; do
  [ -f "$src" ] || continue
  check_refs "$src"
done
for root in workflow docs; do
  [ -d "$root" ] && [ ! -L "$root" ] && check_guides "$root"
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

# 5. The Claude Code plugin (.claude-plugin/), if there is one: both manifests,
#    matching plugin names, and listed skills that exist, without init-project.
#    `claude plugin validate .` in CI checks the JSON itself; this reads only a
#    small text subset of it, like check_skill does for frontmatter:
#    - plugin.json's plugin name is its first "name" key, so keep "name" first;
#    - the marketplace's plugin name is the first "name" key after "plugins";
#    - plugin.json's "skills" is one [...] array of "./.agents/skills/<name>"
#      strings, each with a SKILL.md, and none of them init-project.
#    A project that doesn't publish the plugin can delete .claude-plugin/.
str_re='"([^"]*)"'
first_name_re='"name"[[:space:]]*:[[:space:]]*"([^"]*)"'
skills_re='"skills"[[:space:]]*:[[:space:]]*\[([^]]*)]'
pm=.claude-plugin/plugin.json
mm=.claude-plugin/marketplace.json
if [ -e .claude-plugin ]; then
  [ -f "$pm" ] || fail "missing $pm (.claude-plugin/ needs both manifests)"
  [ -f "$mm" ] || fail "missing $mm (.claude-plugin/ needs both manifests)"
  if [ -f "$pm" ] && [ -f "$mm" ]; then
    read_file "$pm" content
    plugin_name=""
    [[ $content =~ $first_name_re ]] && plugin_name=${BASH_REMATCH[1]}
    [ -n "$plugin_name" ] || fail "$pm has no \"name\""
    if [[ $content =~ $skills_re ]]; then
      rest=${BASH_REMATCH[1]}
      listed=0
      while [[ $rest =~ $str_re ]]; do
        p=${BASH_REMATCH[1]}
        rest=${rest#*"${BASH_REMATCH[0]}"}
        listed=$((listed + 1))
        p=${p%/}
        sn=${p#./.agents/skills/}
        if [ "$sn" = "$p" ] || [ -z "$sn" ] || [[ $sn == */* ]]; then
          fail "$pm lists skill path $p; use ./.agents/skills/<name>"
        elif [ "$sn" = init-project ]; then
          fail "$pm exposes init-project; new projects are bootstrapped from the template, not the plugin"
        elif [ ! -f ".agents/skills/$sn/SKILL.md" ]; then
          fail "$pm lists $p, which has no SKILL.md"
        fi
      done
      [ "$listed" -gt 0 ] || fail "$pm lists no skills"
    else
      fail "$pm needs a \"skills\" array of ./.agents/skills/<name> folders"
    fi
    read_file "$mm" content
    market_name=""
    if [[ $content == *'"plugins"'* ]]; then
      rest=${content#*'"plugins"'}
      [[ $rest =~ $first_name_re ]] && market_name=${BASH_REMATCH[1]}
    fi
    if [ -z "$market_name" ]; then
      fail "$mm lists no plugin"
    elif [ -n "$plugin_name" ] && [ "$market_name" != "$plugin_name" ]; then
      fail "$mm lists plugin '$market_name', but $pm names it '$plugin_name'"
    fi
  fi
fi

if [ "$errors" -gt 0 ]; then
  echo "Workflow integrity: $errors problem(s) found."
  exit 1
fi
echo "Workflow integrity: OK."
