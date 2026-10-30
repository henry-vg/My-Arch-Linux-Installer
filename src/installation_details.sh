read_password() {
    local prompt="$1" password confirmation
    local -n password_output="$2"

    log "Password rules:"
    log "  - Must be 3 to 32 characters long."
    log "  - Only letters, digits, and punctuation."
    printf '\n'

    while true; do
        read -rsp "$(input_prompt "$prompt")" password
        printf '\n'
        read -rsp "$(input_prompt 'Confirm password: ')" confirmation
        printf '\n'

        if [[ "$password" != "$confirmation" ]]; then
            log "[ERROR] Passwords do not match. Try again."
        elif [[ ${#password} -lt 3 || ${#password} -gt 32 || "$password" =~ [^a-zA-Z0-9[:punct:]] ]]; then
            log "[ERROR] Invalid password. Follow the rules above and try again."
        else
            password_output="$password"
            return
        fi
    done
}

collect_installation_details() {
    local -n hostname_output="$1" username_output="$2"

    read_password "Enter root password: " "$3"
    log "[INFO] Root password set."
    printf '\n'

    log "Username rules:"
    log "  - Must start with a lowercase letter."
    log "  - Only lowercase letters, digits, hyphens, and underscores."
    log "  - Must be 3 to 32 characters long."
    log "  - Cannot already exist on the system."
    printf '\n'

    while true; do
        read -rp "$(input_prompt 'Enter username: ')" username_output
        if [[ ! "$username_output" =~ ^[a-z][-a-z0-9_]{2,31}$ ]] || id "$username_output" &>/dev/null; then
            log "[ERROR] Invalid or existing username. Try again."
            continue
        fi
        break
    done
    log "[INFO] Username set."
    printf '\n'

    read_password "Enter $username_output's password: " "$4"
    log "[INFO] $username_output's password set."
    printf '\n'

    log "Hostname rules:"
    log "  - Only lowercase letters, digits, hyphens, and dots."
    log "  - Cannot start or end with a hyphen."
    log "  - At most 253 characters total and 63 per segment."
    printf '\n'

    while true; do
        read -rp "$(input_prompt 'Enter hostname: ')" hostname_output
        if [[ ! "$hostname_output" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] || [[ ${#hostname_output} -gt 253 ]]; then
            log "[ERROR] Invalid hostname. Try again."
            continue
        fi
        break
    done
    log "[INFO] Hostname set."
}
