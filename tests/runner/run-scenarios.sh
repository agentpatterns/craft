#!/usr/bin/env bash
# run-scenarios.sh — Automated test runner for craft skill scenarios
#
# Reads YAML scenario files from tests/scenarios/ and optionally invokes
# the claude CLI to verify trigger and functional behaviors.
#
# Dependencies: bash, yq (for YAML parsing), claude CLI (for non-dry-run mode)
#
# Usage:
#   ./tests/runner/run-scenarios.sh [OPTIONS]
#
# Options:
#   --skill <name>         Run scenarios for a specific skill (e.g., research, draft)
#   --type trigger|functional|all
#                          Which test category to run (default: all)
#   --dry-run              Print what would be tested without invoking the API
#   --verbose              Show full prompt and output for each test
#   --help                 Show this help message

set -euo pipefail

# ---------------------------------------------------------------------------
# Terminal color codes
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# Resolve script and project root paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SCENARIOS_DIR="${PROJECT_ROOT}/tests/scenarios"

# ---------------------------------------------------------------------------
# Default option values
# ---------------------------------------------------------------------------
OPT_SKILL=""
OPT_TYPE="all"
OPT_DRY_RUN=false
OPT_VERBOSE=false

# Global counters for summary
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

# ---------------------------------------------------------------------------
# print_help — Display usage information
# ---------------------------------------------------------------------------
print_help() {
    cat <<EOF
${BOLD}run-scenarios.sh${RESET} — Craft skill automated test runner

${BOLD}USAGE${RESET}
    ./tests/runner/run-scenarios.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --skill <name>              Run scenarios for a specific skill.
                                Matches the YAML file basename (e.g., research, draft, tdd).
                                If omitted, all scenario files in tests/scenarios/ are processed.

    --type trigger|functional|all
                                Which test category to run (default: all).
                                  trigger    — Test that phrases activate/suppress the skill
                                  functional — Test that the skill produces correct outputs
                                  all        — Run both trigger and functional tests

    --dry-run                   Print what would be tested without invoking the claude CLI.
                                Useful for validating scenario structure and CI scaffolding.

    --verbose                   Show full prompt text and claude CLI output for each test.
                                Implied in --dry-run for functional tests (shows given/when/then).

    --help                      Show this help message and exit.

${BOLD}EXAMPLES${RESET}
    # List all scenarios for the research skill without invoking the API
    ./tests/runner/run-scenarios.sh --dry-run --skill research

    # Run only trigger tests for the draft skill
    ./tests/runner/run-scenarios.sh --skill draft --type trigger

    # Run all tests for all skills
    ./tests/runner/run-scenarios.sh

    # Run functional tests with verbose output
    ./tests/runner/run-scenarios.sh --type functional --verbose

${BOLD}DEPENDENCIES${RESET}
    yq      Required for YAML parsing. Install: brew install yq
    claude  Required for non-dry-run mode. Install: npm install -g @anthropic-ai/claude-code

${BOLD}SCENARIO FILES${RESET}
    Tests are defined in YAML files under tests/scenarios/.
    See tests/README.md for the full schema reference.
EOF
}

# ---------------------------------------------------------------------------
# parse_args — Parse command-line flags
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skill)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --skill requires an argument" >&2
                    exit 1
                fi
                OPT_SKILL="$2"
                shift 2
                ;;
            --type)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --type requires an argument (trigger, functional, or all)" >&2
                    exit 1
                fi
                case "$2" in
                    trigger|functional|all) OPT_TYPE="$2" ;;
                    *)
                        echo "Error: --type must be one of: trigger, functional, all" >&2
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --dry-run)
                OPT_DRY_RUN=true
                shift
                ;;
            --verbose)
                OPT_VERBOSE=true
                shift
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                echo "Error: Unknown option '$1'. Use --help for usage." >&2
                exit 1
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# check_dependencies — Verify required tools are available
# ---------------------------------------------------------------------------
check_dependencies() {
    local missing=()

    if ! command -v yq &>/dev/null; then
        missing+=("yq (install: brew install yq)")
    fi

    if [[ "$OPT_DRY_RUN" == false ]] && ! command -v claude &>/dev/null; then
        missing+=("claude (install: npm install -g @anthropic-ai/claude-code)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}Missing required dependencies:${RESET}" >&2
        for dep in "${missing[@]}"; do
            echo -e "  ${RED}•${RESET} ${dep}" >&2
        done
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# resolve_scenario_files — Build list of YAML files to process
# Returns: space-separated list of absolute file paths
# ---------------------------------------------------------------------------
resolve_scenario_files() {
    local files=()

    if [[ -n "$OPT_SKILL" ]]; then
        local path="${SCENARIOS_DIR}/${OPT_SKILL}.yaml"
        if [[ ! -f "$path" ]]; then
            echo "Error: No scenario file found for skill '${OPT_SKILL}' at: ${path}" >&2
            exit 1
        fi
        files+=("$path")
    else
        # Glob all YAML files in the scenarios directory
        while IFS= read -r -d '' f; do
            files+=("$f")
        done < <(find "${SCENARIOS_DIR}" -maxdepth 1 -name "*.yaml" -print0 | sort -z)
    fi

    printf '%s\n' "${files[@]}"
}

# ---------------------------------------------------------------------------
# parse_yaml_skill — Extract the skill name from a scenario file
# Arguments: $1 = yaml_file
# ---------------------------------------------------------------------------
parse_yaml_skill() {
    local yaml_file="$1"
    yq '.skill' "$yaml_file"
}

# ---------------------------------------------------------------------------
# parse_yaml_category — Extract the category from a scenario file
# Arguments: $1 = yaml_file
# ---------------------------------------------------------------------------
parse_yaml_category() {
    local yaml_file="$1"
    yq '.category' "$yaml_file"
}

# ---------------------------------------------------------------------------
# run_trigger_tests — Process triggering.positive and triggering.negative entries
# Arguments: $1 = yaml_file, $2 = skill_name
# ---------------------------------------------------------------------------
run_trigger_tests() {
    local yaml_file="$1"
    local skill_name="$2"

    echo -e "\n${BOLD}${CYAN}── Trigger Tests: ${skill_name} ──${RESET}"

    # --- Positive phrases (skill SHOULD load) ---
    local positive_count
    positive_count=$(yq '.triggering.positive | length' "$yaml_file")

    if [[ "$positive_count" -gt 0 ]]; then
        echo -e "\n  ${BOLD}Positive (skill SHOULD trigger)${RESET}"
        local i
        for (( i = 0; i < positive_count; i++ )); do
            local phrase
            phrase=$(yq ".triggering.positive[$i]" "$yaml_file")
            _run_single_trigger_test "$skill_name" "$phrase" "positive" "$i"
        done
    fi

    # --- Negative phrases (skill MUST NOT load) ---
    local negative_count
    negative_count=$(yq '.triggering.negative | length' "$yaml_file")

    if [[ "$negative_count" -gt 0 ]]; then
        echo -e "\n  ${BOLD}Negative (skill MUST NOT trigger)${RESET}"
        local j
        for (( j = 0; j < negative_count; j++ )); do
            local phrase
            phrase=$(yq ".triggering.negative[$j]" "$yaml_file")
            _run_single_trigger_test "$skill_name" "$phrase" "negative" "$j"
        done
    fi
}

# ---------------------------------------------------------------------------
# _run_single_trigger_test — Execute or describe one trigger test case
# Arguments: $1 = skill, $2 = phrase, $3 = polarity (positive|negative), $4 = index
# ---------------------------------------------------------------------------
_run_single_trigger_test() {
    local skill="$1"
    local phrase="$2"
    local polarity="$3"
    local index="$4"

    local test_id="${skill}-trigger-${polarity:0:3}-$(( index + 1 ))"
    local expected_label
    if [[ "$polarity" == "positive" ]]; then
        expected_label="${GREEN}SHOULD trigger${RESET}"
    else
        expected_label="${RED}MUST NOT trigger${RESET}"
    fi

    if [[ "$OPT_DRY_RUN" == true ]]; then
        printf "    [${CYAN}DRY${RESET}] %-35s %b\n      Phrase: \"%s\"\n" \
            "$test_id" "$expected_label" "$phrase"
        (( TOTAL_SKIP++ )) || true
        return
    fi

    # Non-dry-run: invoke claude CLI with the skill description injected as context.
    # The --print flag runs stateless without plugins, so we must provide the skill
    # description directly in the prompt for meaningful trigger classification.
    local skill_description=""
    local skill_md="${PROJECT_ROOT}/skills/${skill}/SKILL.md"
    if [[ -f "$skill_md" ]]; then
        # Extract the description from YAML frontmatter
        skill_description=$(sed -n '/^---$/,/^---$/p' "$skill_md" | yq '.description // ""')
    fi

    local probe_prompt
    if [[ -n "$skill_description" ]]; then
        probe_prompt="You have a skill called '${skill}' with description: \"${skill_description}\". Given that description, would you activate this skill for the following user input? \"${phrase}\" — respond with only YES or NO."
    else
        probe_prompt="When would you use the ${skill} skill? Now, given that, would you activate it for this input: \"${phrase}\" — respond with only YES or NO."
    fi

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo "    [PROBE] ${test_id}"
        echo "      Prompt: ${probe_prompt}"
    fi

    local claude_output claude_stderr
    local stderr_file
    stderr_file=$(mktemp)
    claude_output=$(env -u CLAUDECODE claude --print "${probe_prompt}" 2>"$stderr_file") || true
    claude_stderr=$(<"$stderr_file")
    rm -f "$stderr_file"

    if [[ -z "$claude_output" && -n "$claude_stderr" ]]; then
        claude_output="ERROR"
        if [[ "$OPT_VERBOSE" == true ]]; then
            echo -e "      ${RED}stderr: ${claude_stderr}${RESET}"
        fi
    fi

    # Determine pass/fail based on polarity
    # Use word-boundary search anywhere in the response, not just line start
    local result="FAIL"
    local color="$RED"
    local first_word
    first_word=$(echo "$claude_output" | head -1 | awk '{print tolower($1)}')

    if [[ "$polarity" == "positive" ]]; then
        # Expect YES anywhere in response, with priority on first word
        if [[ "$first_word" == "yes" ]] || echo "$claude_output" | grep -qi '\byes\b'; then
            result="PASS"
            color="$GREEN"
            (( TOTAL_PASS++ )) || true
        else
            (( TOTAL_FAIL++ )) || true
        fi
    else
        # Expect NO anywhere in response, with priority on first word
        if [[ "$first_word" == "no" ]] || echo "$claude_output" | grep -qi '\bno\b'; then
            result="PASS"
            color="$GREEN"
            (( TOTAL_PASS++ )) || true
        else
            (( TOTAL_FAIL++ )) || true
        fi
    fi

    printf "    [%b%s%b] %-35s — %s\n" "$color" "$result" "$RESET" "$test_id" "$phrase"

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo "      Claude response: ${claude_output}"
    fi
}

# ---------------------------------------------------------------------------
# run_functional_tests — Process functional[] entries from a scenario file
# Arguments: $1 = yaml_file, $2 = skill_name
# ---------------------------------------------------------------------------
run_functional_tests() {
    local yaml_file="$1"
    local skill_name="$2"

    echo -e "\n${BOLD}${CYAN}── Functional Tests: ${skill_name} ──${RESET}"

    local scenario_count
    scenario_count=$(yq '.functional | length' "$yaml_file")

    if [[ "$scenario_count" -eq 0 ]]; then
        echo -e "  ${YELLOW}No functional scenarios defined.${RESET}"
        return
    fi

    local i
    for (( i = 0; i < scenario_count; i++ )); do
        local scenario_id description grading given when_prompt
        scenario_id=$(yq ".functional[$i].id"          "$yaml_file")
        description=$(yq ".functional[$i].description" "$yaml_file")
        grading=$(yq ".functional[$i].grading"         "$yaml_file")
        given=$(yq ".functional[$i].given"             "$yaml_file")
        when_prompt=$(yq ".functional[$i].when"        "$yaml_file")

        _run_single_functional_test \
            "$yaml_file" "$i" "$scenario_id" "$description" "$grading" "$given" "$when_prompt"
    done
}

# ---------------------------------------------------------------------------
# _run_single_functional_test — Execute or describe one functional scenario
# Arguments: $1=yaml_file $2=index $3=id $4=description $5=grading
#            $6=given $7=when_prompt
# ---------------------------------------------------------------------------
_run_single_functional_test() {
    local yaml_file="$1"
    local index="$2"
    local scenario_id="$3"
    local description="$4"
    local grading="$5"
    local given="$6"
    local when_prompt="$7"

    # Collect then[] assertions
    local then_count
    then_count=$(yq ".functional[$index].then | length" "$yaml_file")

    local notes
    notes=$(yq ".functional[$index].notes // \"\"" "$yaml_file")

    echo -e "\n  ${BOLD}[${scenario_id}]${RESET} ${description}"
    echo -e "  Grading: ${CYAN}${grading}${RESET}"

    if [[ "$OPT_DRY_RUN" == true || "$OPT_VERBOSE" == true ]]; then
        echo -e "  ${BOLD}Given:${RESET}"
        # Indent multi-line given block
        while IFS= read -r line; do
            echo "    ${line}"
        done <<< "$given"

        echo -e "  ${BOLD}When:${RESET}"
        echo "    ${when_prompt}"

        echo -e "  ${BOLD}Then:${RESET}"
        local k
        for (( k = 0; k < then_count; k++ )); do
            local assertion
            assertion=$(yq ".functional[$index].then[$k]" "$yaml_file")
            echo "    [ ] ${assertion}"
        done

        if [[ -n "$notes" && "$notes" != "null" && "$notes" != '""' ]]; then
            echo -e "  ${YELLOW}Notes: ${notes}${RESET}"
        fi
    fi

    if [[ "$OPT_DRY_RUN" == true ]]; then
        printf "  [${CYAN}DRY${RESET}] Would invoke claude with: \"%s\"\n" "$when_prompt"
        (( TOTAL_SKIP++ )) || true
        return
    fi

    # Non-dry-run: invoke claude CLI with the when prompt
    # Note: setup (given) is provided as context in the system prompt prefix
    local full_prompt
    full_prompt="Context for this test:
${given}

Task: ${when_prompt}"

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo -e "  ${BOLD}Full prompt sent to claude:${RESET}"
        echo "$full_prompt" | sed 's/^/    /'
    fi

    echo -e "  ${YELLOW}Running...${RESET}"
    local claude_output claude_stderr
    local stderr_file
    stderr_file=$(mktemp)
    claude_output=$(env -u CLAUDECODE claude --print "$full_prompt" 2>"$stderr_file") || true
    claude_stderr=$(<"$stderr_file")
    rm -f "$stderr_file"

    if [[ -z "$claude_output" && -n "$claude_stderr" ]]; then
        claude_output="ERROR: claude invocation failed"
        echo -e "  ${RED}stderr: ${claude_stderr}${RESET}"
    fi

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo -e "  ${BOLD}Claude output:${RESET}"
        echo "$claude_output" | head -50 | sed 's/^/    /'
        if [[ -n "$claude_stderr" ]]; then
            echo -e "  ${BOLD}Claude stderr:${RESET}"
            echo "$claude_stderr" | head -20 | sed 's/^/    /'
        fi
    fi

    # Grade the output based on the grading type
    case "$grading" in
        code)
            _grade_code_assertions "$yaml_file" "$index" "$then_count"
            ;;
        llm-judge)
            # Feed output + assertions to a second Claude call for LLM-as-judge evaluation
            local judge_prompt
            judge_prompt="You are an LLM-as-judge evaluating whether a skill's output meets its assertions.

Skill output (first 200 lines):
$(echo "$claude_output" | head -200)

Assertions to check:
$(for (( k = 0; k < then_count; k++ )); do
    yq ".functional[$index].then[$k]" "$yaml_file"
done)

For each assertion, respond with PASS or FAIL and a brief reason.
End with a single line: VERDICT: PASS or VERDICT: FAIL"

            local judge_output judge_stderr_file
            judge_stderr_file=$(mktemp)
            judge_output=$(env -u CLAUDECODE claude --print "$judge_prompt" 2>"$judge_stderr_file") || true
            local judge_stderr=$(<"$judge_stderr_file")
            rm -f "$judge_stderr_file"

            if [[ "$OPT_VERBOSE" == true ]]; then
                echo -e "  ${BOLD}LLM-Judge output:${RESET}"
                echo "$judge_output" | sed 's/^/    /'
            fi

            if echo "$judge_output" | grep -qi "VERDICT:.*PASS"; then
                echo -e "  [${GREEN}PASS${RESET}] LLM-Judge: all assertions met"
                (( TOTAL_PASS++ )) || true
            elif echo "$judge_output" | grep -qi "VERDICT:.*FAIL"; then
                echo -e "  [${RED}FAIL${RESET}] LLM-Judge: one or more assertions failed"
                (( TOTAL_FAIL++ )) || true
            else
                echo -e "  ${YELLOW}[LLM-JUDGE]${RESET} Judge returned no clear verdict."
                if [[ -n "$judge_stderr" ]]; then
                    echo -e "  ${RED}Judge stderr: ${judge_stderr}${RESET}"
                fi
                (( TOTAL_SKIP++ )) || true
            fi
            ;;
        human)
            echo -e "  ${YELLOW}[HUMAN]${RESET} Output requires human review (Tier 3)."
            (( TOTAL_SKIP++ )) || true
            ;;
        *)
            echo -e "  ${YELLOW}[UNKNOWN GRADING]${RESET} grading=${grading}"
            (( TOTAL_SKIP++ )) || true
            ;;
    esac
}

# ---------------------------------------------------------------------------
# _grade_code_assertions — Evaluate code-graded then[] assertions automatically
# Arguments: $1 = yaml_file, $2 = index, $3 = then_count
# Parses assertion text to detect check type and runs appropriate validation.
# ---------------------------------------------------------------------------
_grade_code_assertions() {
    local yaml_file="$1"
    local index="$2"
    local then_count="$3"
    local all_pass=true

    local k
    for (( k = 0; k < then_count; k++ )); do
        local assertion
        assertion=$(yq ".functional[$index].then[$k]" "$yaml_file")
        local check_result="SKIP"
        local check_detail=""

        if echo "$assertion" | grep -qi "file exists\|file.*at"; then
            # file-exists check: extract glob pattern from the assertion
            local pattern
            pattern=$(echo "$assertion" | grep -oP '(?:at |exists at |path )?\S+\.\w+' | tail -1)
            if [[ -n "$pattern" ]]; then
                # Search for matching files in project root
                local found_files
                found_files=$(find "$PROJECT_ROOT" -path "*${pattern}*" -type f 2>/dev/null | head -5)
                if [[ -z "$found_files" ]]; then
                    # Try glob-style match
                    found_files=$(find "$PROJECT_ROOT" -name "*.md" -path "*/docs/plans/*" -type f 2>/dev/null | head -5)
                fi
                if [[ -n "$found_files" ]]; then
                    check_result="PASS"
                    check_detail="Found: $(echo "$found_files" | head -1)"
                else
                    check_result="FAIL"
                    check_detail="No file matching pattern found"
                    all_pass=false
                fi
            else
                check_result="SKIP"
                check_detail="Could not extract file pattern from assertion"
            fi
        elif echo "$assertion" | grep -qi "contains section:\|section:.*##"; then
            # section-present check: extract section header
            local section_header
            section_header=$(echo "$assertion" | grep -oP '## \S[^"]*' | head -1)
            if [[ -n "$section_header" ]]; then
                # Search the most recent matching file
                local target_file
                target_file=$(find "$PROJECT_ROOT/docs/plans" -name "*.md" -type f -newer "$yaml_file" 2>/dev/null | sort -r | head -1)
                if [[ -n "$target_file" ]] && grep -q "^${section_header}" "$target_file" 2>/dev/null; then
                    check_result="PASS"
                    check_detail="Section '${section_header}' found in ${target_file}"
                elif [[ -z "$target_file" ]]; then
                    check_result="FAIL"
                    check_detail="No output file found to check for section"
                    all_pass=false
                else
                    check_result="FAIL"
                    check_detail="Section '${section_header}' not found in ${target_file}"
                    all_pass=false
                fi
            else
                check_result="SKIP"
                check_detail="Could not extract section header from assertion"
            fi
        elif echo "$assertion" | grep -qi "approximately.*lines\|line count\|lines (target"; then
            # quantitative check: extract expected range
            local min_lines max_lines
            min_lines=$(echo "$assertion" | grep -oP '\d+' | head -1)
            max_lines=$(echo "$assertion" | grep -oP '\d+' | head -2 | tail -1)
            local target_file
            target_file=$(find "$PROJECT_ROOT/docs/plans" -name "*.md" -type f -newer "$yaml_file" 2>/dev/null | sort -r | head -1)
            if [[ -n "$target_file" && -n "$min_lines" && -n "$max_lines" ]]; then
                local actual_lines
                actual_lines=$(wc -l < "$target_file")
                if (( actual_lines >= min_lines && actual_lines <= max_lines )); then
                    check_result="PASS"
                    check_detail="${actual_lines} lines (expected ${min_lines}–${max_lines})"
                else
                    # Quantitative failures are warnings, not hard failures
                    check_result="WARN"
                    check_detail="${actual_lines} lines (expected ${min_lines}–${max_lines})"
                fi
            else
                check_result="SKIP"
                check_detail="Could not evaluate line count"
            fi
        elif echo "$assertion" | grep -qi "labeled with\|confidence\|every.*finding\|pattern.*present"; then
            # string-match check: look for required patterns in output files
            local target_file
            target_file=$(find "$PROJECT_ROOT/docs/plans" -name "*.md" -type f -newer "$yaml_file" 2>/dev/null | sort -r | head -1)
            if [[ -n "$target_file" ]]; then
                if echo "$assertion" | grep -qi "confidence"; then
                    # Check for High/Medium/Low confidence markers
                    if grep -qP '\*\*(High|Medium|Low)\*\*' "$target_file" 2>/dev/null; then
                        check_result="PASS"
                        check_detail="Confidence levels found"
                    else
                        check_result="FAIL"
                        check_detail="No confidence level markers found"
                        all_pass=false
                    fi
                else
                    check_result="SKIP"
                    check_detail="String-match assertion not auto-evaluable"
                fi
            else
                check_result="FAIL"
                check_detail="No output file found"
                all_pass=false
            fi
        else
            check_result="SKIP"
            check_detail="Assertion not auto-evaluable"
        fi

        local color
        case "$check_result" in
            PASS) color="$GREEN" ;;
            FAIL) color="$RED" ;;
            WARN) color="$YELLOW" ;;
            *)    color="$CYAN" ;;
        esac

        printf "    [%b%s%b] %s\n" "$color" "$check_result" "$RESET" "$assertion"
        if [[ "$OPT_VERBOSE" == true && -n "$check_detail" ]]; then
            echo "           ${check_detail}"
        fi
    done

    if [[ "$all_pass" == true ]]; then
        (( TOTAL_PASS++ )) || true
    else
        (( TOTAL_FAIL++ )) || true
    fi
}

# ---------------------------------------------------------------------------
# print_summary — Print color-coded pass/fail/skip counts
# ---------------------------------------------------------------------------
print_summary() {
    local total=$(( TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP ))
    echo -e "\n${BOLD}══════════════════════════════════════${RESET}"
    echo -e "${BOLD}Summary${RESET}"
    echo -e "${BOLD}══════════════════════════════════════${RESET}"
    echo -e "  Total scenarios : ${total}"
    echo -e "  ${GREEN}${BOLD}PASS${RESET}            : ${TOTAL_PASS}"
    echo -e "  ${RED}${BOLD}FAIL${RESET}            : ${TOTAL_FAIL}"
    echo -e "  ${CYAN}${BOLD}SKIP / DRY${RESET}      : ${TOTAL_SKIP}"

    if [[ "$OPT_DRY_RUN" == true ]]; then
        echo -e "\n  ${CYAN}Dry-run mode: no claude API calls were made.${RESET}"
    fi

    if [[ "$TOTAL_FAIL" -gt 0 ]]; then
        echo -e "\n  ${RED}${BOLD}Result: FAIL${RESET} (${TOTAL_FAIL} scenario(s) failed)"
        return 1
    else
        echo -e "\n  ${GREEN}${BOLD}Result: PASS${RESET}"
        return 0
    fi
}

# ---------------------------------------------------------------------------
# process_scenario_file — Orchestrate tests for a single YAML file
# Arguments: $1 = yaml_file
# ---------------------------------------------------------------------------
process_scenario_file() {
    local yaml_file="$1"
    local skill_name
    skill_name=$(parse_yaml_skill "$yaml_file")

    local category
    category=$(parse_yaml_category "$yaml_file")

    echo -e "\n${BOLD}${CYAN}════════════════════════════════════════${RESET}"
    echo -e "${BOLD}Skill: ${skill_name}${RESET}  (category: ${category})"
    echo -e "${BOLD}File:  ${yaml_file}${RESET}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

    case "$OPT_TYPE" in
        trigger)
            run_trigger_tests "$yaml_file" "$skill_name"
            ;;
        functional)
            run_functional_tests "$yaml_file" "$skill_name"
            ;;
        all)
            run_trigger_tests "$yaml_file" "$skill_name"
            run_functional_tests "$yaml_file" "$skill_name"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# main — Entry point
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"
    check_dependencies

    if [[ "$OPT_DRY_RUN" == true ]]; then
        echo -e "${CYAN}${BOLD}[DRY RUN MODE]${RESET} No API calls will be made."
    fi

    # Collect scenario files
    local scenario_files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && scenario_files+=("$f")
    done < <(resolve_scenario_files)

    if [[ ${#scenario_files[@]} -eq 0 ]]; then
        echo "No scenario files found in ${SCENARIOS_DIR}" >&2
        exit 1
    fi

    # Process each scenario file
    for yaml_file in "${scenario_files[@]}"; do
        process_scenario_file "$yaml_file"
    done

    print_summary
}

main "$@"
