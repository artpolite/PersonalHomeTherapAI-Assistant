#!/usr/bin/env bash
# KI_Studio_OS_install.sh
# KI_STUDIO_DIRECTIVE_HEADER

set -u
set -o pipefail

KI_STUDIO_DIREKTIVE_ACTIVE="${KI_STUDIO_DIREKTIVE_ACTIVE:-1}"

KI_STUDIO_ROOT="${KI_STUDIO_ROOT:-/mnt/KI_Studio}"
KI_STUDIO_OS_HOME="$KI_STUDIO_ROOT/KI_Studio_OS_Home"
KI_STUDIO_OS_PROFILES="$KI_STUDIO_OS_HOME/KI_Studio_OS_Profiles"
KI_STUDIO_OS_LOGS="$KI_STUDIO_OS_HOME/KI_Studio_OS_Logs"
KI_STUDIO_OS_STATE="$KI_STUDIO_OS_HOME/KI_Studio_OS_State"
KI_STUDIO_OS_PROTOKOLL="$KI_STUDIO_OS_HOME/KI_Studio_OS_Protokoll"
KI_STUDIO_OS_STATUS_FILE="$KI_STUDIO_OS_HOME/KI_Studio_OS_Status.json"
KI_STUDIO_OS_INSTALL_STATUS_FILE="$KI_STUDIO_OS_STATE/KI_Studio_OS_Install_Status.json"
KI_STUDIO_OS_ACTION_LOG="$KI_STUDIO_OS_PROTOKOLL/KI_Studio_OS_Aktions_Protokoll.jsonl"
KI_STUDIO_OS_LOGFILE="$KI_STUDIO_OS_LOGS/KI_Studio_OS_install_$(date '+%Y%m%d_%H%M%S').log"

mkdir -p "$KI_STUDIO_OS_LOGS" "$KI_STUDIO_OS_STATE" "$KI_STUDIO_OS_PROTOKOLL"

ki_os_now_iso() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

ki_os_log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$1" | tee -a "$KI_STUDIO_OS_LOGFILE" >/dev/null
}

ki_os_json_escape() {
    local s="${1:-}"
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/}
    printf '%s' "$s"
}

ki_os_write_install_status() {
    local status="${1:-unbekannt}"
    local step="${2:-}"
    local profile="${3:-}"

    cat > "$KI_STUDIO_OS_INSTALL_STATUS_FILE" <<KI_STUDIO_OS_INSTALL_STATUS_WRITE_EOF
{
  "KI_Studio_Element": "KI_Studio_OS_Install_Status",
  "KI_Studio_Status": "$(ki_os_json_escape "$status")",
  "KI_Studio_Letzter_Schritt": "$(ki_os_json_escape "$step")",
  "KI_Studio_Letztes_Profil": "$(ki_os_json_escape "$profile")",
  "KI_Studio_Letzte_Aktualisierung": "$(ki_os_now_iso)"
}
KI_STUDIO_OS_INSTALL_STATUS_WRITE_EOF
}

ki_os_write_home_status() {
    local status="${1:-unbekannt}"
    local profile="${2:-}"

    cat > "$KI_STUDIO_OS_STATUS_FILE" <<KI_STUDIO_OS_HOME_STATUS_WRITE_EOF
{
  "KI_Studio_Element": "KI_Studio_OS_Status",
  "KI_Studio_Status": "$(ki_os_json_escape "$status")",
  "KI_Studio_Kanonische_Quelle": "$(ki_os_json_escape "$KI_STUDIO_OS_HOME")",
  "KI_Studio_Host_Anker": "$(ki_os_json_escape "$HOME/.KI_Studio_Home")",
  "KI_Studio_Letztes_Profil": "$(ki_os_json_escape "$profile")",
  "KI_Studio_Letzte_Aktualisierung": "$(ki_os_now_iso)"
}
KI_STUDIO_OS_HOME_STATUS_WRITE_EOF
}

ki_os_append_action_log() {
    local action="${1:-}"
    local result="${2:-}"
    local profile="${3:-}"
    local detail="${4:-}"

    printf '{"KI_Studio_Zeit":"%s","KI_Studio_Aktion":"%s","KI_Studio_Resultat":"%s","KI_Studio_Profil":"%s","KI_Studio_Detail":"%s"}\n' \
        "$(ki_os_now_iso)" \
        "$(ki_os_json_escape "$action")" \
        "$(ki_os_json_escape "$result")" \
        "$(ki_os_json_escape "$profile")" \
        "$(ki_os_json_escape "$detail")" \
        >> "$KI_STUDIO_OS_ACTION_LOG"
}

ki_os_has_yad() {
    command -v yad >/dev/null 2>&1
}

ki_os_has_zenity() {
    command -v zenity >/dev/null 2>&1
}

ki_os_running_in_terminal() {
    [[ -t 0 && -t 1 ]]
}

ki_os_relaunch_in_terminal_if_needed() {
    local arg="${1:-}"

    if ki_os_running_in_terminal; then
        return 0
    fi

    if ki_os_has_yad || ki_os_has_zenity; then
        return 0
    fi

    if command -v gnome-terminal >/dev/null 2>&1; then
        if [[ -n "$arg" ]]; then
            gnome-terminal -- bash -lc "\"$0\" \"$arg\"; printf '\nENTER zum Beenden...'; read -r"
        else
            gnome-terminal -- bash -lc "\"$0\"; printf '\nENTER zum Beenden...'; read -r"
        fi
        exit 0
    fi

    if command -v x-terminal-emulator >/dev/null 2>&1; then
        if [[ -n "$arg" ]]; then
            x-terminal-emulator -e bash -lc "\"$0\" \"$arg\"; printf '\nENTER zum Beenden...'; read -r"
        else
            x-terminal-emulator -e bash -lc "\"$0\"; printf '\nENTER zum Beenden...'; read -r"
        fi
        exit 0
    fi
}

ki_os_info() {
    local msg="$1"

    if ki_os_has_yad; then
        yad --info --title="KI_Studio_OS_install" --text="$msg" --button=OK:0 >/dev/null 2>&1 || true
    elif ki_os_has_zenity; then
        zenity --info --title="KI_Studio_OS_install" --text="$msg" >/dev/null 2>&1 || true
    else
        printf '%b\n' "$msg"
    fi
}

ki_os_error_dialog() {
    local msg="$1"

    if ki_os_has_yad; then
        yad --error --title="KI_Studio_OS_install" --text="$msg" --button=OK:0 >/dev/null 2>&1 || true
    elif ki_os_has_zenity; then
        zenity --error --title="KI_Studio_OS_install" --text="$msg" >/dev/null 2>&1 || true
    else
        printf 'FEHLER: %b\n' "$msg" >&2
    fi
}

ki_os_confirm() {
    local msg="$1"
    local answer=""

    if ki_os_has_yad; then
        yad --question --title="KI_Studio_OS_install" --text="$msg" --button=Ja:0 --button=Nein:1 >/dev/null 2>&1
        return $?
    fi

    if ki_os_has_zenity; then
        zenity --question --title="KI_Studio_OS_install" --text="$msg" --ok-label="Ja" --cancel-label="Nein" >/dev/null 2>&1
        return $?
    fi

    printf '%b\n' "$msg"
    read -r -p "Fortfahren? [j/N]: " answer
    case "$answer" in
        j|J|ja|Ja|JA|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

ki_os_normalize() {
    printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed 's/[^[:alnum:]]/_/g'
}

ki_os_list_profile_labels() {
    local f base label
    for f in "$KI_STUDIO_OS_PROFILES"/KI_Studio_OS_Profile_*.manifest; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        label="${base#KI_Studio_OS_Profile_}"
        label="${label%.manifest}"
        printf '%s\n' "$label"
    done
}

ki_os_resolve_manifest() {
    local wanted="${1:-}"
    local normalized_wanted f base label

    [[ -n "$wanted" ]] || return 1

    if [[ -f "$wanted" ]]; then
        printf '%s\n' "$wanted"
        return 0
    fi

    normalized_wanted="$(ki_os_normalize "$wanted")"

    for f in "$KI_STUDIO_OS_PROFILES"/KI_Studio_OS_Profile_*.manifest; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        label="${base#KI_Studio_OS_Profile_}"
        label="${label%.manifest}"
        if [[ "$(ki_os_normalize "$label")" == "$normalized_wanted" ]]; then
            printf '%s\n' "$f"
            return 0
        fi
    done

    return 1
}

ki_os_choose_profile() {
    local labels=()
    local chosen=""
    local i=1
    local label=""

    while IFS= read -r label; do
        [[ -n "$label" ]] || continue
        labels+=("$label")
    done < <(ki_os_list_profile_labels)

    if [[ ${#labels[@]} -eq 0 ]]; then
        return 1
    fi

    if ki_os_has_yad; then
        local yad_args=()
        yad_args+=(--list --radiolist --title="KI_Studio_OS_Profile_Auswahl")
        yad_args+=(--text="Bitte Profil auswählen:")
        yad_args+=(--column="" --column="Profil")
        local idx=0
        for label in "${labels[@]}"; do
            if [[ $idx -eq 0 ]]; then
                yad_args+=(TRUE "$label")
            else
                yad_args+=(FALSE "$label")
            fi
            idx=$((idx+1))
        done
        chosen="$(yad "${yad_args[@]}" 2>/dev/null || true)"
        [[ -n "$chosen" ]] || return 1
        printf '%s\n' "$chosen"
        return 0
    fi

    if ki_os_has_zenity; then
        local zenity_args=()
        zenity_args+=(--list --radiolist --title="KI_Studio_OS_Profile_Auswahl")
        zenity_args+=(--text="Bitte Profil auswählen:")
        zenity_args+=(--column="" --column="Profil")
        local idx=0
        for label in "${labels[@]}"; do
            if [[ $idx -eq 0 ]]; then
                zenity_args+=(TRUE "$label")
            else
                zenity_args+=(FALSE "$label")
            fi
            idx=$((idx+1))
        done
        chosen="$(zenity "${zenity_args[@]}" 2>/dev/null || true)"
        [[ -n "$chosen" ]] || return 1
        printf '%s\n' "$chosen"
        return 0
    fi

    printf 'Verfügbare Profile:\n'
    for label in "${labels[@]}"; do
        printf '  %d) %s\n' "$i" "$label"
        i=$((i+1))
    done

    while true; do
        local choice=""
        read -r -p "Profil wählen [1-${#labels[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#labels[@]} )); then
            printf '%s\n' "${labels[$((choice-1))]}"
            return 0
        fi
        printf 'Ungültige Auswahl.\n'
    done
}

ki_os_manifest_packages() {
    local manifest="$1"
    grep -vE '^[[:space:]]*(#|$)' "$manifest" 2>/dev/null || true
}

ki_os_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

ki_os_run_step() {
    local step="$1"
    shift
    local cmd=( "$@" )

    while true; do
        ki_os_log "Starte: $step"
        if "${cmd[@]}" 2>&1 | tee -a "$KI_STUDIO_OS_LOGFILE"; then
            ki_os_log "Erledigt: $step"
            return 0
        fi

        ki_os_log "FEHLER bei: $step"
        ki_os_write_install_status "fehler" "$step" "${KI_STUDIO_OS_CURRENT_PROFILE:-}"
        ki_os_append_action_log "$step" "fehler" "${KI_STUDIO_OS_CURRENT_PROFILE:-}" "Schritt fehlgeschlagen"

        if ! ki_os_confirm "Fehler bei Schritt:\n\n$step\n\nErneut versuchen?"; then
            return 1
        fi
    done
}

KI_STUDIO_OS_CURRENT_PROFILE=""

ki_os_main() {
    local requested_profile="${1:-}"
    local selected_profile=""
    local manifest=""
    local packages=()
    local missing_packages=()
    local pkg=""
    local summary=""

    ki_os_relaunch_in_terminal_if_needed "$requested_profile"

    if [[ -n "$requested_profile" ]]; then
        selected_profile="$requested_profile"
    else
        selected_profile="$(ki_os_choose_profile)" || {
            ki_os_info "Kein Profil ausgewählt."
            exit 1
        }
    fi

    manifest="$(ki_os_resolve_manifest "$selected_profile")" || {
        ki_os_error_dialog "Profil nicht gefunden:\n$selected_profile"
        exit 1
    }

    KI_STUDIO_OS_CURRENT_PROFILE="$(basename "$manifest")"
    KI_STUDIO_OS_CURRENT_PROFILE="${KI_STUDIO_OS_CURRENT_PROFILE#KI_Studio_OS_Profile_}"
    KI_STUDIO_OS_CURRENT_PROFILE="${KI_STUDIO_OS_CURRENT_PROFILE%.manifest}"

    mapfile -t packages < <(ki_os_manifest_packages "$manifest")

    if [[ ${#packages[@]} -eq 0 ]]; then
        ki_os_error_dialog "Manifest enthält keine Pakete:\n$manifest"
        exit 1
    fi

    for pkg in "${packages[@]}"; do
        if ki_os_package_installed "$pkg"; then
            ki_os_log "$pkg ist bereits installiert."
        else
            missing_packages+=("$pkg")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        ki_os_write_install_status "nichts_zu_tun" "paketpruefung" "$KI_STUDIO_OS_CURRENT_PROFILE"
        ki_os_write_home_status "nichts_zu_tun" "$KI_STUDIO_OS_CURRENT_PROFILE"
        ki_os_append_action_log "install" "nichts_zu_tun" "$KI_STUDIO_OS_CURRENT_PROFILE" "Alle Pakete bereits installiert"
        ki_os_info "Alle Pakete des Profils \"$KI_STUDIO_OS_CURRENT_PROFILE\" sind bereits installiert."
        exit 0
    fi

    summary="Profil: $KI_STUDIO_OS_CURRENT_PROFILE\n\nFolgende Pakete fehlen noch:\n"
    for pkg in "${missing_packages[@]}"; do
        summary="${summary}- ${pkg}\n"
    done
    summary="${summary}\nDies ist eine SYSTEM-Aktion und verändert Ubuntu-Pakete."

    if [[ "$KI_STUDIO_DIREKTIVE_ACTIVE" == "1" ]]; then
        if ! ki_os_confirm "$summary"; then
            ki_os_write_install_status "abgebrochen" "bestaetigung" "$KI_STUDIO_OS_CURRENT_PROFILE"
            ki_os_write_home_status "abgebrochen" "$KI_STUDIO_OS_CURRENT_PROFILE"
            ki_os_append_action_log "install" "abgebrochen" "$KI_STUDIO_OS_CURRENT_PROFILE" "Benutzer hat SYSTEM-Aktion abgelehnt"
            exit 1
        fi
    fi

    ki_os_write_install_status "gestartet" "sudo_v" "$KI_STUDIO_OS_CURRENT_PROFILE"
    ki_os_write_home_status "laufend" "$KI_STUDIO_OS_CURRENT_PROFILE"
    ki_os_append_action_log "install" "gestartet" "$KI_STUDIO_OS_CURRENT_PROFILE" "Installationslauf begonnen"

    ki_os_run_step "Sudo-Berechtigung prüfen" sudo -v || {
        ki_os_error_dialog "sudo konnte nicht bestätigt werden."
        ki_os_write_home_status "fehler" "$KI_STUDIO_OS_CURRENT_PROFILE"
        exit 1
    }

    ki_os_run_step "Update der Paketlisten" sudo apt-get update || {
        ki_os_error_dialog "apt-get update fehlgeschlagen."
        ki_os_write_home_status "fehler" "$KI_STUDIO_OS_CURRENT_PROFILE"
        exit 1
    }

    for pkg in "${missing_packages[@]}"; do
        ki_os_write_install_status "laufend" "Installation $pkg" "$KI_STUDIO_OS_CURRENT_PROFILE"
        ki_os_run_step "Installation $pkg" sudo apt-get install -y "$pkg" || {
            ki_os_error_dialog "Installation fehlgeschlagen:\n$pkg"
            ki_os_write_home_status "fehler" "$KI_STUDIO_OS_CURRENT_PROFILE"
            exit 1
        }
    done

    ki_os_write_install_status "erfolgreich" "abgeschlossen" "$KI_STUDIO_OS_CURRENT_PROFILE"
    ki_os_write_home_status "bereit" "$KI_STUDIO_OS_CURRENT_PROFILE"
    ki_os_append_action_log "install" "erfolgreich" "$KI_STUDIO_OS_CURRENT_PROFILE" "Profil erfolgreich installiert"

    ki_os_info "Installation abgeschlossen.\n\nProfil: $KI_STUDIO_OS_CURRENT_PROFILE\nLog: $KI_STUDIO_OS_LOGFILE"
}

ki_os_main "${1:-}"
