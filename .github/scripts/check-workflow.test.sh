#!/usr/bin/env bash
# Tests for check-workflow.sh. Each case builds a tiny throwaway workflow tree (one
# `demo` command, its skill, the entry files, one guide), applies one change, runs
# the real check on it, and asserts the exit code and the message.
#
#   bash .github/scripts/check-workflow.test.sh
#
# The fixture is synthetic, so the test doesn't depend on which commands a project
# ships. CI runs it next to the check (.github/workflows/workflow-check.yml).
set -uo pipefail
case "$0" in
  */*) cd "${0%/*}/../.." || exit 1 ;;
  *) cd ../.. || exit 1 ;;
esac

script=.github/scripts/check-workflow.sh
checker=""
while IFS= read -r line || [ -n "$line" ]; do
  checker+="${line%$'\r'}"$'\n'
done < "$script"

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

make_fixture() {
  local d=$1
  mkdir -p "$d/.claude/commands" "$d/.agents/skills/demo" "$d/.github/scripts" "$d/workflow" || return 1
  printf '%s' "$checker" > "$d/$script"
  printf -- '- `/demo` — see `workflow/guide.md`.\n' > "$d/CLAUDE.md"
  printf -- 'Skills: `demo`.\n' > "$d/AGENTS.md"
  printf -- '- `/demo`\n' > "$d/.github/copilot-instructions.md"
  printf -- '| `/demo` | Demo |\n' > "$d/workflow/README.md"
  printf -- '| `/demo` | Demo |\n' > "$d/workflow/model-strategy.md"
  printf -- '# Guide\n' > "$d/workflow/guide.md"
  printf -- '---\nname: demo\n---\n\nFirst read `.agents/skills/demo/SKILL.md`.\n' > "$d/.claude/commands/demo.md"
  printf -- '---\nname: demo\ndescription: Demo skill.\n---\n\nSee `workflow/guide.md`.\n' > "$d/.agents/skills/demo/SKILL.md"
  printf 'issue_tracker=github\n' > "$d/.workflow-config"
}

# One function per case; each runs inside a fresh fixture.
healthy() { :; }
quoted_and_crlf_names() {
  printf -- '---\r\nname: "demo"  \r\ndescription:\t%s\t \r\n---\r\n\r\nSee `workflow/guide.md`.\r\n' "'false'" > .agents/skills/demo/SKILL.md
  printf -- "---\nname: 'demo'\n---\n\nFirst read \`.agents/skills/demo/SKILL.md\`.\n" > .claude/commands/demo.md
}
command_without_skill() { rm -r .agents/skills/demo; }
skill_without_command() { mkdir .agents/skills/other && printf -- '---\nname: other\ndescription: Other skill.\n---\n' > .agents/skills/other/SKILL.md; }
skill_dir_without_skill_md() { mkdir .agents/skills/empty; }
command_not_delegating() { printf -- '---\nname: demo\n---\n\nDo the demo.\n' > .claude/commands/demo.md; }
wrong_frontmatter_name() { printf -- '---\nname: demo2\ndescription: Demo skill.\n---\n' > .agents/skills/demo/SKILL.md; }
unlisted_command() {
  mkdir .agents/skills/extra &&
    printf -- '---\nname: extra\ndescription: Extra skill.\n---\n' > .agents/skills/extra/SKILL.md &&
    printf -- '---\nname: extra\n---\n\nFirst read `.agents/skills/extra/SKILL.md`.\n' > .claude/commands/extra.md
}
dangling_reference() { printf -- 'See `workflow/missing.md`.\n' >> workflow/guide.md; }
jira_without_project() { printf 'issue_tracker=jira\n' > .workflow-config; }
unknown_tracker() { printf 'issue_tracker=linear\n' > .workflow-config; }

# Skill frontmatter cases. demo_skill <line>...: rewrites the demo skill as just
# these lines between `---` delimiters.
demo_skill() { printf -- '%s\n' '---' "$@" '---' > .agents/skills/demo/SKILL.md; }
reordered_and_optional_fields() {
  demo_skill '# A comment line.' "description: Plain text — with Unicode (é), commas, and it's fine." \
    'license: MIT' 'metadata:' '  name: nested' '  description: ""' '' 'name: demo' &&
    printf -- '\nname: body-text\ndescription:\n' >> .agents/skills/demo/SKILL.md
}
single_quoted_name_closed_at_eof() { printf -- '---\nname: %s\ndescription: %s\n---' "'demo'" '"123"' > .agents/skills/demo/SKILL.md; }
description_only_command() { printf -- '---\ndescription: Demo command.\n---\n\nFirst read `.agents/skills/demo/SKILL.md`.\n' > .claude/commands/demo.md; }
description_only_command_bad_skill() { description_only_command && demo_skill 'name: demo'; }
no_opening_delimiter() { printf -- 'name: demo\ndescription: Demo skill.\n---\n' > .agents/skills/demo/SKILL.md; }
no_closing_delimiter() { printf -- '---\nname: demo\ndescription: Demo skill.\n\nSee `workflow/guide.md`.\n' > .agents/skills/demo/SKILL.md; }
no_name() { demo_skill 'description: Demo skill.'; }
description_only_in_body() { printf -- '---\nname: demo\n---\n\ndescription: Only in the body.\n' > .agents/skills/demo/SKILL.md; }
description_only_nested() { demo_skill 'name: demo' 'metadata:' '  description: Nested only.'; }
duplicate_name_after_both() { demo_skill 'name: demo' 'description: Demo skill.' 'name: demo'; }
duplicate_description() { demo_skill 'name: demo' 'description: Demo skill.' 'description: Again.'; }
name_continued_on_next_line() { demo_skill 'name: demo' '  extra' 'description: Demo skill.'; }
empty_description() { demo_skill 'name: demo' 'description:'; }
whitespace_only_description() { demo_skill 'name: demo' 'description:   '; }
quoted_empty_description() { demo_skill 'name: demo' 'description: ""'; }
blank_quoted_description() { demo_skill 'name: demo' $'description: \' \t \''; }
unquoted_number_description() { demo_skill 'name: demo' 'description: 123'; }
bare_boolean_description() { demo_skill 'name: demo' 'description: False'; }
block_description() { demo_skill 'name: demo' 'description: >' '  Folded text that' '  continues here.'; }
escape_in_description() { demo_skill 'name: demo' 'description: "Line one\nline two"'; }
name_with_extra_word() { demo_skill 'name: demo extra' 'description: Demo skill.'; }
padded_quoted_name() { demo_skill 'name: "demo "' 'description: Demo skill.'; }
unclosed_quote() { demo_skill 'name: "demo' 'description: Demo skill.'; }
mismatched_quotes() { demo_skill "name: \"demo'" 'description: Demo skill.'; }
text_after_closing_quote() { demo_skill "name: 'demo' extra" 'description: Demo skill.'; }
comment_after_name() { demo_skill 'name: demo # the demo skill' 'description: Demo skill.'; }
state_after_valid_skill() { mkdir .agents/skills/other && printf -- '---\nname: other\n---\n' > .agents/skills/other/SKILL.md; }
state_after_invalid_skill() { mkdir .agents/skills/aaa && printf -- '---\nname: aaa\ndescription: First skill.\n' > .agents/skills/aaa/SKILL.md; }

passed=0
failed=0
n=0

# run_case <description> <expected exit code> <expected output substring> <setup function>
run_case() {
  local desc=$1 want_status=$2 want_text=$3 setup=$4 dir out status
  n=$((n + 1))
  dir="$tmp/case$n"
  if ! make_fixture "$dir" || ! (cd "$dir" && "$setup"); then
    echo "not ok - $desc (fixture setup failed)"
    failed=$((failed + 1))
    return
  fi
  out=$(bash "$dir/$script" 2>&1)
  status=$?
  if [ "$status" = "$want_status" ] && [[ $out == *"$want_text"* ]]; then
    echo "ok - $desc"
    passed=$((passed + 1))
  else
    echo "not ok - $desc: exit $status (expected $want_status), output should contain: $want_text"
    echo "$out"
    failed=$((failed + 1))
  fi
}

run_case "healthy tree passes" 0 "Workflow integrity: OK." healthy
run_case "quoted and CRLF frontmatter names pass" 0 "Workflow integrity: OK." quoted_and_crlf_names
run_case "command without a skill" 1 ".claude/commands/demo.md has no matching .agents/skills/demo/SKILL.md" command_without_skill
run_case "skill without a command" 1 ".agents/skills/other has no matching .claude/commands/other.md" skill_without_command
run_case "skill dir without SKILL.md" 1 ".agents/skills/empty has no SKILL.md" skill_dir_without_skill_md
run_case "command that doesn't delegate" 1 ".claude/commands/demo.md must delegate to .agents/skills/demo/SKILL.md" command_not_delegating
run_case "wrong frontmatter name" 1 ".agents/skills/demo/SKILL.md: frontmatter name must be 'demo'" wrong_frontmatter_name
run_case "command missing from the entry files" 1 "CLAUDE.md doesn't list the extra command" unlisted_command
run_case "dangling guide reference" 1 "workflow/guide.md references workflow/missing.md, which does not exist" dangling_reference
run_case "jira tracker without a project" 1 "issue_tracker=jira needs jira_project" jira_without_project
run_case "unknown tracker" 1 "must set issue_tracker=github or issue_tracker=jira" unknown_tracker

skill=".agents/skills/demo/SKILL.md: frontmatter"
run_case "fields in either order, optional and nested fields, body text" 0 "Workflow integrity: OK." reordered_and_optional_fields
run_case "single-quoted name, quoted number, closing --- at EOF" 0 "Workflow integrity: OK." single_quoted_name_closed_at_eof
run_case "command with only description: and a valid skill" 0 "Workflow integrity: OK." description_only_command
run_case "command with only description: and a skill without one" 1 "$skill must have exactly one description: field, found 0" description_only_command_bad_skill
run_case "no opening ---" 1 "$skill must start with a '---' line" no_opening_delimiter
run_case "no closing ---" 1 "$skill has no closing '---' line" no_closing_delimiter
run_case "no name" 1 "$skill must have exactly one name: field, found 0" no_name
run_case "description only in the body" 1 "$skill must have exactly one description: field, found 0" description_only_in_body
run_case "description only nested" 1 "$skill must have exactly one description: field, found 0" description_only_nested
run_case "duplicate name after both fields" 1 "$skill must have exactly one name: field, found 2" duplicate_name_after_both
run_case "duplicate description" 1 "$skill must have exactly one description: field, found 2" duplicate_description
run_case "name continued on the next line" 1 "$skill name: continues on the next line; write it as one line of text" name_continued_on_next_line
run_case "empty description" 1 "$skill description: is empty" empty_description
run_case "whitespace-only description" 1 "$skill description: is empty" whitespace_only_description
run_case "quoted empty description" 1 "$skill description: is empty" quoted_empty_description
run_case "whitespace-only quoted description" 1 "$skill description: is empty" blank_quoted_description
run_case "unquoted number as description" 1 "$skill description: needs quotes; write it as one line of text" unquoted_number_description
run_case "bare boolean as description" 1 "$skill description: needs quotes (YAML reads bare true, false and null" bare_boolean_description
run_case "block description" 1 "$skill description: needs quotes; write it as one line of text" block_description
run_case "escape in a double-quoted description" 1 "$skill description: has its own quote or a backslash inside the quotes" escape_in_description
run_case "name with an extra word" 1 "$skill name must be 'demo'" name_with_extra_word
run_case "padding inside a quoted name" 1 "$skill name must be 'demo'" padded_quoted_name
run_case "unclosed quote" 1 "$skill name: has an unclosed quote or text after the closing quote" unclosed_quote
run_case "mismatched quotes" 1 "$skill name: has an unclosed quote or text after the closing quote" mismatched_quotes
run_case "text after the closing quote" 1 "$skill name: has an unclosed quote or text after the closing quote" text_after_closing_quote
run_case "comment after the name" 1 "$skill name: can't have ': ' or ' #'" comment_after_name
run_case "no state carried over from a valid skill" 1 ".agents/skills/other/SKILL.md: frontmatter must have exactly one description: field, found 0" state_after_valid_skill
run_case "no state carried over from an invalid skill" 1 "Workflow integrity: 2 problem(s) found." state_after_invalid_skill

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
