read_password() {
    local prompt="$1" password_variable_name="$2" password confirmation

    log "Password Rules:"
    log "  - Must be 3 to 32 characters long."
    log "  - Can contain letters, digits, and punctuation."
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
            printf -v "$password_variable_name" '%s' "$password"
            return
        fi
    done
}

collect_system_configuration() {
    local -n hostname_output=$1 username_output=$2

    read_password "Insert root password: " "$3"
    log "[OK] Root password set successfully."
    printf '\n'

    log "Username Rules:"
    log "  - Must start with a lowercase letter."
    log "  - Can only contain lowercase letters, numbers, hyphens and underscores."
    log "  - Must be between 3 and 32 characters long."
    log "  - Cannot already exist on the system."
    printf '\n'

    while true; do
        read -rp "$(input_prompt 'Insert the desired username: ')" username_output
        if [[ ! "$username_output" =~ ^[a-z][-a-z0-9_]{2,31}$ ]] || id "$username_output" &>/dev/null; then
            log "[ERROR] Invalid or existing username. Try again."
            continue
        fi
        break
    done
    log "[OK] Username set successfully."
    printf '\n'

    read_password "Insert $username_output's password: " "$4"
    log "[OK] $username_output's password set successfully."
    printf '\n'

    log "Hostname Rules:"
    log "  - Only lowercase letters, numbers, hyphens, and dots."
    log "  - Cannot start or end with a hyphen."
    log "  - Max 253 characters total, and 63 per segment."
    printf '\n'

    while true; do
        read -rp "$(input_prompt 'Insert the desired hostname: ')" hostname_output
        if [[ ! "$hostname_output" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] || [[ ${#hostname_output} -gt 253 ]]; then
            log "[ERROR] Invalid hostname. Try again."
            continue
        fi
        break
    done
    log "[OK] Hostname set successfully."
}
