#!/usr/bin/env bash
# KI_Studio_OS_ORC.sh
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
KI_STUDIO_OS_VERSION_FILE="$KI_STUDIO_OS_HOME/KI_Studio_OS_VERSION"
KI_STUDIO_OS_INSTALL_SCRIPT="$KI_STUDIO_OS_HOME/KI_Studio_OS_install.sh"
KI_STUDIO_OS_HOST_ANCHOR="$HOME/.KI_Studio_Home"

ki_os_orc_show_help() {
    cat <<'KI_STUDIO_OS_ORC_HELP_EOF'
KI_Studio_OS_ORC.sh

Befehle:
  version              Versionsnummer ausgeben
  status               OS-HOME-Status anzeigen
  pruefen              Struktur und Basiskomponenten prüfen
  profiles             Verfügbare Install-Profile anzeigen
  liste                Alias für profiles
  install [profil]     KI_Studio_OS_install.sh aufrufen
  logs                 Letztes Install-Log anzeigen
  hilfe                Diese Hilfe anzeigen
KI_STUDIO_OS_ORC_HELP_EOF
}

ki_os_orc_version() {
    if [[ -f "$KI_STUDIO_OS_VERSION_FILE" ]]; then
        cat "$KI_STUDIO_OS_VERSION_FILE"
    else
        echo "unbekannt"
    fi
}

ki_os_orc_status() {
    echo "════════════════════════════════════════════════════════════"
    echo "KI_Studio_OS_Home Status"
    echo "════════════════════════════════════════════════════════════"
    echo "Root                 : $KI_STUDIO_ROOT"
    echo "KI_Studio_OS_Home    : $KI_STUDIO_OS_HOME"
    echo "Host-Anker           : $KI_STUDIO_OS_HOST_ANCHOR"
    echo "Version              : $(ki_os_orc_version)"
    echo ""

    if [[ -f "$KI_STUDIO_OS_STATUS_FILE" ]]; then
        echo "KI_Studio_OS_Status.json:"
        cat "$KI_STUDIO_OS_STATUS_FILE"
        echo ""
    else
        echo "Statusdatei fehlt: $KI_STUDIO_OS_STATUS_FILE"
        echo ""
    fi

    if [[ -f "$KI_STUDIO_OS_STATE/KI_Studio_OS_Install_Status.json" ]]; then
        echo "KI_Studio_OS_Install_Status.json:"
        cat "$KI_STUDIO_OS_STATE/KI_Studio_OS_Install_Status.json"
        echo ""
    fi
}

ki_os_orc_profiles() {
    local found=0
    echo "Verfügbare Profile:"
    for f in "$KI_STUDIO_OS_PROFILES"/KI_Studio_OS_Profile_*.manifest; do
        [[ -f "$f" ]] || continue
        found=1
        basename "$f" .manifest | sed 's/^KI_Studio_OS_Profile_/- /'
    done

    if [[ $found -eq 0 ]]; then
        echo "- keine Profile gefunden"
    fi
}

ki_os_orc_pruefen() {
    local missing=0

    echo "Prüfe KI_Studio_OS_Home ..."
    for path in \
        "$KI_STUDIO_OS_HOME" \
        "$KI_STUDIO_OS_PROFILES" \
        "$KI_STUDIO_OS_LOGS" \
        "$KI_STUDIO_OS_STATE" \
        "$KI_STUDIO_OS_PROTOKOLL" \
        "$KI_STUDIO_OS_HOME/KI_Studio_OS_Backups" \
        "$KI_STUDIO_OS_HOME/KI_Studio_OS_Vorlagen" \
        "$KI_STUDIO_OS_HOME/KI_Studio_OS_Legacy" \
        "$KI_STUDIO_OS_INSTALL_SCRIPT" \
        "$KI_STUDIO_OS_VERSION_FILE" \
        "$KI_STUDIO_OS_STATUS_FILE"
    do
        if [[ -e "$path" ]]; then
            echo "✔ $path"
        else
            echo "⚠ fehlt: $path"
            missing=1
        fi
    done

    echo ""
    echo "Host-Anker:"
    if [[ -d "$KI_STUDIO_OS_HOST_ANCHOR" ]]; then
        echo "✔ vorhanden: $KI_STUDIO_OS_HOST_ANCHOR"
    else
        echo "⚠ nicht vorhanden: $KI_STUDIO_OS_HOST_ANCHOR"
    fi

    echo ""
    echo "Werkzeuge:"
    for cmd in apt-get dpkg sudo; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✔ $cmd"
        else
            echo "⚠ fehlt: $cmd"
        fi
    done

    if command -v yad >/dev/null 2>&1; then
        echo "✔ yad"
    elif command -v zenity >/dev/null 2>&1; then
        echo "✔ zenity"
    else
        echo "⚠ weder yad noch zenity gefunden – Terminal-Fallback nötig"
    fi

    return "$missing"
}

ki_os_orc_logs() {
    local latest_log=""
    latest_log="$(ls -1t "$KI_STUDIO_OS_LOGS"/KI_Studio_OS_install_*.log 2>/dev/null | head -n 1 || true)"

    if [[ -z "$latest_log" ]]; then
        echo "Keine Install-Logs gefunden."
        return 0
    fi

    echo "Letztes Log: $latest_log"
    echo "------------------------------------------------------------"
    tail -n 80 "$latest_log" 2>/dev/null || cat "$latest_log"
}

case "${1:-hilfe}" in
    version)
        ki_os_orc_version
        ;;
    status)
        ki_os_orc_status
        ;;
    pruefen|check)
        ki_os_orc_pruefen
        ;;
    profiles|liste)
        ki_os_orc_profiles
        ;;
    install)
        shift
        exec "$KI_STUDIO_OS_INSTALL_SCRIPT" "$@"
        ;;
    logs)
        ki_os_orc_logs
        ;;
    hilfe|help|-h|--help|"")
        ki_os_orc_show_help
        ;;
    *)
        echo "Unbekannter Befehl: $1"
        echo ""
        ki_os_orc_show_help
        exit 2
        ;;
esac
