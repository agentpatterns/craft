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

    # Non-dry-run: invoke claude CLI
    # The probe prompt asks Claude when it would use the skill, then sends the phrase
    local probe_prompt
    probe_prompt="When would you use the ${skill} skill? Now, given that, would you activate it for this input: \"${phrase}\" — respond with only YES or NO."

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo "    [PROBE] ${test_id}"
        echo "      Prompt: ${probe_prompt}"
    fi

    local claude_output
    claude_output=$(claude --print "${probe_prompt}" 2>/dev/null || echo "ERROR")

    # Determine pass/fail based on polarity
    local result="FAIL"
    local color="$RED"
    if [[ "$polarity" == "positive" ]]; then
        # Expect YES in response
        if echo "$claude_output" | grep -qi "^yes"; then
            result="PASS"
            color="$GREEN"
            (( TOTAL_PASS++ )) || true
        else
            (( TOTAL_FAIL++ )) || true
        fi
    else
        # Expect NO in response
        if echo "$claude_output" | grep -qi "^no"; then
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
    local claude_output
    claude_output=$(claude --print "$full_prompt" 2>/dev/null || echo "ERROR: claude invocation failed")

    if [[ "$OPT_VERBOSE" == true ]]; then
        echo -e "  ${BOLD}Claude output:${RESET}"
        echo "$claude_output" | head -50 | sed 's/^/    /'
    fi

    # For code-graded scenarios, grade is deferred to filesystem checks (manual or CI).
    # For llm-judge and human scenarios, we note the grading method required.
    case "$grading" in
        code)
            echo -e "  ${YELLOW}[CODE-GRADE]${RESET} Filesystem assertions require post-run inspection."
            echo -e "  Run the assertions listed under 'Then' against your working directory."
            (( TOTAL_SKIP++ )) || true
            ;;
        llm-judge)
            echo -e "  ${YELLOW}[LLM-JUDGE]${RESET} Output requires LLM-as-judge evaluation (Tier 2)."
            (( TOTAL_SKIP++ )) || true
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
