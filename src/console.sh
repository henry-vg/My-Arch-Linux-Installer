colors_enabled() {
    [[ -t 1 && -t 2 && ${TERM:-dumb} != dumb ]]
}

dim_output() {
    if colors_enabled; then
        printf '\e[0;2m'
    fi
}

reset_output() {
    if colors_enabled; then
        printf '\e[0m'
    fi
}

log() {
    local color_code="37"

    case "$1" in
        '[INFO]'*) color_code="32" ;;
        '[WARNING]'*) color_code="33" ;;
        '[ERROR]'*) color_code="31" ;;
    esac

    if colors_enabled; then
        printf '\e[0;%sm%s\e[0;2m\n' "$color_code" "$1"
    else
        printf '%s\n' "$1"
    fi
}

input_prompt() {
    if colors_enabled; then
        printf '\e[0;36m%s\e[0;2m' "$1"
    else
        printf '%s' "$1"
    fi
}

confirm_action() {
    local question="$1" default_answer="$2" response answer_choices

    case "$default_answer" in
        yes) answer_choices="Y/n" ;;
        no) answer_choices="y/N" ;;
        *) log "[ERROR] Invalid confirmation default: $default_answer."; return 2 ;;
    esac

    IFS= read -rp "$(input_prompt "$question [$answer_choices] ")" response || return 1

    case "${response,,}" in
        y|yes) return 0 ;;
        '') [[ "$default_answer" == yes ]] ;;
        *) return 1 ;;
    esac
}

pause() {
    if colors_enabled; then
        printf '\n\e[0;1;36m%s\e[0m\n' "$1"
    else
        printf '\n%s\n' "$1"
    fi
    if [[ -t 0 ]]; then
        stty intr '^C'
    fi
    trap 'exit 130' INT
    if ! confirm_action "Start this step?" yes; then
        log "[INFO] Installation canceled."
        exit 1
    fi
    trap '' INT
    if [[ -t 0 ]]; then
        stty intr undef
    fi
    printf '\n'
    dim_output
}

