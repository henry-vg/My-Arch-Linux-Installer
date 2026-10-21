read_password() {
    local prompt="$1" password_variable_name="$2" password confirmation

    echo "Password Rules:"
    echo "  - Must be 3 to 32 characters long."
    echo "  - Can contain letters, digits, and punctuation."
    echo

    while true; do
        read -rsp "$prompt" password
        echo
        read -rsp "Confirm password: " confirmation
        echo

        if [[ "$password" != "$confirmation" ]]; then
            echo "[ERROR] Passwords do not match. Try again."
        elif [[ ${#password} -lt 3 || ${#password} -gt 32 || "$password" =~ [^a-zA-Z0-9[:punct:]] ]]; then
            echo "[ERROR] Invalid password. Follow the rules above and try again."
        else
            printf -v "$password_variable_name" '%s' "$password"
            return
        fi
    done
}

collect_system_configuration() {
    read_password "Insert root password: " ROOT_PASSWORD
    echo "[OK] Root password set successfully."
    echo

    echo "Username Rules:"
    echo "  - Must start with a lowercase letter."
    echo "  - Can only contain lowercase letters, numbers, hyphens and underscores."
    echo "  - Must be between 3 and 32 characters long."
    echo "  - Cannot already exist on the system."
    echo

    while true; do
        read -rp "Insert the desired username: " USERNAME
        if [[ ! "$USERNAME" =~ ^[a-z][-a-z0-9_]{2,31}$ ]] || id "$USERNAME" &>/dev/null; then
            echo "[ERROR] Invalid or existing username. Try again."
            continue
        fi
        break
    done
    echo "[OK] Username set successfully."
    echo

    read_password "Insert $USERNAME's password: " USER_PASSWORD
    echo "[OK] $USERNAME's password set successfully."
    echo

    echo "Hostname Rules:"
    echo "  - Only lowercase letters, numbers, hyphens, and dots."
    echo "  - Cannot start or end with a hyphen."
    echo "  - Max 253 characters total, and 63 per segment."
    echo

    while true; do
        read -rp "Insert the desired hostname: " HOSTNAME
        if [[ ! "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] || [[ ${#HOSTNAME} -gt 253 ]]; then
            echo "[ERROR] Invalid hostname. Try again."
            continue
        fi
        break
    done
    echo "[OK] Hostname set successfully."
}
