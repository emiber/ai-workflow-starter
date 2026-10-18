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
  printf -- '---\nname: demo\n---\n\nSee `workflow/guide.md`.\n' > "$d/.agents/skills/demo/SKILL.md"
  printf 'issue_tracker=github\n' > "$d/.workflow-config"
}

# One function per case; each runs inside a fresh fixture.
healthy() { :; }
quoted_and_crlf_names() {
  printf -- '---\r\nname: "demo"  \r\n---\r\n\r\nSee `workflow/guide.md`.\r\n' > .agents/skills/demo/SKILL.md
  printf -- "---\nname: 'demo'\n---\n\nFirst read \`.agents/skills/demo/SKILL.md\`.\n" > .claude/commands/demo.md
}
command_without_skill() { rm -r .agents/skills/demo; }
skill_without_command() { mkdir .agents/skills/other && printf -- '---\nname: other\n---\n' > .agents/skills/other/SKILL.md; }
skill_dir_without_skill_md() { mkdir .agents/skills/empty; }
command_not_delegating() { printf -- '---\nname: demo\n---\n\nDo the demo.\n' > .claude/commands/demo.md; }
wrong_frontmatter_name() { printf -- '---\nname: demo2\n---\n' > .agents/skills/demo/SKILL.md; }
unlisted_command() {
  mkdir .agents/skills/extra &&
    printf -- '---\nname: extra\n---\n' > .agents/skills/extra/SKILL.md &&
    printf -- '---\nname: extra\n---\n\nFirst read `.agents/skills/extra/SKILL.md`.\n' > .claude/commands/extra.md
}
dangling_reference() { printf -- 'See `workflow/missing.md`.\n' >> workflow/guide.md; }
jira_without_project() { printf 'issue_tracker=jira\n' > .workflow-config; }
unknown_tracker() { printf 'issue_tracker=linear\n' > .workflow-config; }

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

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
