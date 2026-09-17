#!/usr/bin/env bash
# =============================================================================
# KI_Studio_LOK_Scan.sh (vC.3)
# READ-ONLY Architektur- und Integrationssensor für KI_Studio
# =============================================================================
#
# Standard:
#   ./KI_Studio_LOK_Scan.sh
#   → lesender Scan, Ausgabe nur im Terminal
#
# Reportmodus:
#   ./KI_Studio_LOK_Scan.sh --report
#   → ausdrückliche Zustimmung erforderlich
#   → speichert Report und Summary im LOK-Modul
#
# Keine Installation.
# Keine Löschung.
# Kein Verschieben.
# Kein Kopieren im Standardmodus.
# Keine Policy-Abhängigkeit.
# Kein Netzwerkzugriff durch dieses Skript.
# =============================================================================

# -----------------------------------------------------------------------------
# Schutz gegen versehentliches "source"
# -----------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    printf '%s\n' \
        "Dieses Skript darf nicht mit source geladen werden." >&2
    return 1 2>/dev/null || exit 1
fi

set -uo pipefail
IFS=$'\n\t'
umask 077

# -----------------------------------------------------------------------------
# Argumente
# -----------------------------------------------------------------------------

KI_STUDIO_REPORT_MODE=false
KI_STUDIO_TERMINAL_RESTART=false

for KI_STUDIO_ARG in "$@"; do
    case "$KI_STUDIO_ARG" in
        --report)
            KI_STUDIO_REPORT_MODE=true
            ;;

        --KI_Studio_LOK_Terminal)
            KI_STUDIO_TERMINAL_RESTART=true
            ;;

        --help|-h)
            cat <<'EOF'
Verwendung:
  KI_Studio_LOK_Scan.sh
      Lesender Scan mit Ausgabe im Terminal.

  KI_Studio_LOK_Scan.sh --report
      Lesender Scan mit ausdrücklich bestätigtem Report.
      Speichert Report und Summary im LOK-Modul.

  KI_Studio_LOK_Scan.sh --help
      Diese Hilfe anzeigen.

Das Skript installiert, löscht, verschiebt und kopiert im Scanmodus nichts.
EOF
            exit 0
            ;;

        *)
            printf 'Unbekanntes Argument: %s\n' "$KI_STUDIO_ARG" >&2
            printf 'Verwende --help für Hilfe.\n' >&2
            exit 1
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Terminal-Autostart bei Doppelklick
# -----------------------------------------------------------------------------

KI_STUDIO_SCRIPT_PATH="$(
    readlink -f -- "${BASH_SOURCE[0]}" 2>/dev/null ||
        printf '%s' "${BASH_SOURCE[0]}"
)"

if [[ "$KI_STUDIO_TERMINAL_RESTART" != true ]] &&
   [[ ! -t 0 || ! -t 1 ]]; then

    if command -v konsole >/dev/null 2>&1; then
        exec konsole --hold -e \
            bash "$KI_STUDIO_SCRIPT_PATH" \
            --KI_Studio_LOK_Terminal "$@"

    elif command -v x-terminal-emulator >/dev/null 2>&1; then
        exec x-terminal-emulator -e \
            bash "$KI_STUDIO_SCRIPT_PATH" \
            --KI_Studio_LOK_Terminal "$@"

    elif command -v qterminal >/dev/null 2>&1; then
        exec qterminal -e \
            bash "$KI_STUDIO_SCRIPT_PATH" \
            --KI_Studio_LOK_Terminal "$@"

    else
        printf '%s\n' \
            "Kein unterstütztes Terminal gefunden." >&2
        printf '%s\n' \
            "Bitte das Skript in einem Terminal starten." >&2
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Kanonische Pfade
# -----------------------------------------------------------------------------

KI_STUDIO_ROOT="/mnt/KI_Studio"
KI_STUDIO_LOK_DIR="$KI_STUDIO_ROOT/KI_Studio_LOK"
KI_STUDIO_LOK_LOG_DIR="$KI_STUDIO_LOK_DIR/KI_Studio_LOK_Logs"

KI_STUDIO_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
KI_STUDIO_REPORT_FILE=""
KI_STUDIO_SUMMARY_FILE=""

# -----------------------------------------------------------------------------
# Farben nur für interaktive Terminalausgabe
# -----------------------------------------------------------------------------

if [[ -t 1 ]] && [[ "$KI_STUDIO_REPORT_MODE" != true ]]; then
    KI_STUDIO_RED=$'\033[0;31m'
    KI_STUDIO_GREEN=$'\033[0;32m'
    KI_STUDIO_YELLOW=$'\033[1;33m'
    KI_STUDIO_BLUE=$'\033[0;34m'
    KI_STUDIO_CYAN=$'\033[0;36m'
    KI_STUDIO_NC=$'\033[0m'
else
    KI_STUDIO_RED=''
    KI_STUDIO_GREEN=''
    KI_STUDIO_YELLOW=''
    KI_STUDIO_BLUE=''
    KI_STUDIO_CYAN=''
    KI_STUDIO_NC=''
fi

# -----------------------------------------------------------------------------
# Ausgabehilfen
# -----------------------------------------------------------------------------

KI_Studio_LOK_Section() {
    printf '\n%s### %s%s\n' \
        "$KI_STUDIO_BLUE" "$1" "$KI_STUDIO_NC"
    printf '%s\n' \
        '-------------------------------------------------------------------------------'
}

KI_Studio_LOK_OK() {
    printf '%s✓ %s%s\n' \
        "$KI_STUDIO_GREEN" "$1" "$KI_STUDIO_NC"
}

KI_Studio_LOK_Warn() {
    printf '%s⚠ %s%s\n' \
        "$KI_STUDIO_YELLOW" "$1" "$KI_STUDIO_NC"
}

KI_Studio_LOK_Info() {
    printf '%s→ %s%s\n' \
        "$KI_STUDIO_CYAN" "$1" "$KI_STUDIO_NC"
}

# -----------------------------------------------------------------------------
# Einfache Redaction für ausgewählte Umgebungsvariablen
# -----------------------------------------------------------------------------

KI_Studio_LOK_Redact() {
    sed -E \
        's/(([A-Za-z_][A-Za-z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_?KEY|APIKEY|CREDENTIAL|AUTH|PRIVATE_KEY)[A-Za-z0-9_]*)=)([^[:space:]]+)/\1<REDACTED>/gI'
}

# -----------------------------------------------------------------------------
# Sichere Zähler
# -----------------------------------------------------------------------------

KI_Studio_LOK_Count_Venvs() {
    local KI_STUDIO_VENV_COUNT='0'

    if [[ -d "$KI_STUDIO_ROOT" ]]; then
        KI_STUDIO_VENV_COUNT="$(
            find "$KI_STUDIO_ROOT" \
                -type f \
                -name 'pyvenv.cfg' \
                -print 2>/dev/null |
                wc -l |
                tr -d '[:space:]'
        )" || KI_STUDIO_VENV_COUNT='0'
    fi

    [[ "$KI_STUDIO_VENV_COUNT" =~ ^[0-9]+$ ]] ||
        KI_STUDIO_VENV_COUNT='0'

    printf '%s' "$KI_STUDIO_VENV_COUNT"
}

KI_Studio_LOK_Count_Ollama_Processes() {
    local KI_STUDIO_OLLAMA_COUNT='0'

    KI_STUDIO_OLLAMA_COUNT="$(
        pgrep -c -f '(^|/)ollama([[:space:]]|$)' 2>/dev/null
    )" || KI_STUDIO_OLLAMA_COUNT='0'

    [[ "$KI_STUDIO_OLLAMA_COUNT" =~ ^[0-9]+$ ]] ||
        KI_STUDIO_OLLAMA_COUNT='0'

    printf '%s' "$KI_STUDIO_OLLAMA_COUNT"
}

# -----------------------------------------------------------------------------
# Report initialisieren
# -----------------------------------------------------------------------------

KI_Studio_LOK_Init_Report() {
    [[ "$KI_STUDIO_REPORT_MODE" == true ]] || return 0

    # Wichtig: Niemals Reportpfade erzeugen, wenn die Platte nicht gemountet ist.
    if [[ ! -d "$KI_STUDIO_ROOT" ]] ||
       ! mountpoint -q "$KI_STUDIO_ROOT" 2>/dev/null; then

        KI_Studio_LOK_Warn \
            "$KI_STUDIO_ROOT ist nicht als Mountpoint verfügbar."
        KI_Studio_LOK_Warn \
            "Reportmodus wird deshalb nicht aktiviert."
        KI_STUDIO_REPORT_MODE=false
        return 0
    fi

    local KI_STUDIO_CONSENT=false

    if command -v zenity >/dev/null 2>&1 &&
       [[ -n "${DISPLAY:-}" ]]; then

        if zenity --question \
            --title="KI_Studio_LOK Report" \
            --text="Diagnosebericht und Summary speichern?\n\nPfad:\n$KI_STUDIO_LOK_LOG_DIR" \
            --width=500; then
            KI_STUDIO_CONSENT=true
        fi
    else
        printf '%s\n' \
            "Diagnosebericht und Summary speichern?"
        printf 'Ziel: %s\n' "$KI_STUDIO_LOK_LOG_DIR"
        read -r -p "Bestätigen? (j/n): " KI_STUDIO_ANSWER

        if [[ "$KI_STUDIO_ANSWER" =~ ^[jJ] ]]; then
            KI_STUDIO_CONSENT=true
        fi
    fi

    if [[ "$KI_STUDIO_CONSENT" != true ]]; then
        KI_Studio_LOK_Info \
            "Report abgelehnt. Es wird nur ins Terminal ausgegeben."
        KI_STUDIO_REPORT_MODE=false
        return 0
    fi

    mkdir -p "$KI_STUDIO_LOK_LOG_DIR"

    KI_STUDIO_REPORT_FILE="$KI_STUDIO_LOK_LOG_DIR/KI_Studio_LOK_Report_${KI_STUDIO_TIMESTAMP}.txt"
    KI_STUDIO_SUMMARY_FILE="$KI_STUDIO_LOK_LOG_DIR/KI_Studio_LOK_Summary_${KI_STUDIO_TIMESTAMP}.txt"

    # Ab hier wird die Terminalausgabe zusätzlich in den Report geschrieben.
    exec > >(tee -a "$KI_STUDIO_REPORT_FILE") 2>&1

    KI_Studio_LOK_OK \
        "Reportmodus aktiv. Ausgabe wird im LOK-Modul gespeichert."
}

# -----------------------------------------------------------------------------
# Scan: Root und Mount
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Root() {
    KI_Studio_LOK_Section "1. KI_STUDIO ROOT UND MOUNT"

    if [[ ! -d "$KI_STUDIO_ROOT" ]]; then
        KI_Studio_LOK_Warn "$KI_STUDIO_ROOT existiert nicht."
        return 0
    fi

    KI_Studio_LOK_OK "$KI_STUDIO_ROOT vorhanden."

    if mountpoint -q "$KI_STUDIO_ROOT" 2>/dev/null; then
        KI_Studio_LOK_OK "Mountpoint erkannt."
    else
        KI_Studio_LOK_Warn "Kein Mountpoint erkannt."
    fi

    printf '\nDateisystem und Belegung:\n'
    df -hT "$KI_STUDIO_ROOT" 2>/dev/null || true

    printf '\nVerzeichnisse, Tiefe 1:\n'
    find "$KI_STUDIO_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf 'DIR  %f\n' 2>/dev/null |
        sort || true

    printf '\nDateien, Tiefe 1:\n'
    find "$KI_STUDIO_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -printf 'FILE %f\n' 2>/dev/null |
        sort || true
}

# -----------------------------------------------------------------------------
# Scan: Architektur
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Architecture() {
    KI_Studio_LOK_Section "2. ARCHITEKTUR UND ORC/LOK"

    local KI_STUDIO_CHECK_PATH
    local KI_STUDIO_CHECK_NAME

    for KI_STUDIO_CHECK_PATH in \
        "$KI_STUDIO_ROOT/KI_Studio_SYS" \
        "$KI_STUDIO_ROOT/KI_Studio_SYS_ORC" \
        "$KI_STUDIO_ROOT/KI_Studio_LOK" \
        "$KI_STUDIO_ROOT/KI_Studio_Runtime_ORC"
    do
        KI_STUDIO_CHECK_NAME="$(basename "$KI_STUDIO_CHECK_PATH")"

        if [[ -d "$KI_STUDIO_CHECK_PATH" ]]; then
            KI_Studio_LOK_OK \
                "Vorhanden: $KI_STUDIO_CHECK_NAME"
        else
            KI_Studio_LOK_Info \
                "Nicht vorhanden: $KI_STUDIO_CHECK_NAME"
        fi
    done
}

# -----------------------------------------------------------------------------
# Scan: Ollama
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Ollama() {
    KI_Studio_LOK_Section "3. OLLAMA"

    if command -v ollama >/dev/null 2>&1; then
        KI_Studio_LOK_OK \
            "ollama im PATH: $(command -v ollama)"
    else
        KI_Studio_LOK_Warn \
            "ollama nicht im PATH."
    fi

    local KI_STUDIO_OLLAMA_COUNT
    KI_STUDIO_OLLAMA_COUNT="$(
        KI_Studio_LOK_Count_Ollama_Processes
    )"

    if [[ "$KI_STUDIO_OLLAMA_COUNT" -gt 0 ]]; then
        KI_Studio_LOK_OK \
            "Ollama-Prozesse: $KI_STUDIO_OLLAMA_COUNT"
    else
        KI_Studio_LOK_Info \
            "Kein laufender Ollama-Prozess."
    fi

    if env | grep -E '^OLLAMA_' 2>/dev/null |
       sort |
       KI_Studio_LOK_Redact; then
        :
    else
        KI_Studio_LOK_Info \
            "Keine OLLAMA-Umgebungsvariablen gefunden."
    fi
}

# -----------------------------------------------------------------------------
# Scan: OpenClaw und Node/npm
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_OpenClaw_Node() {
    KI_Studio_LOK_Section "4. OPENCLAW UND NODE/NPM"

    if command -v openclaw >/dev/null 2>&1; then
        KI_Studio_LOK_OK \
            "openclaw im PATH: $(command -v openclaw)"
    else
        KI_Studio_LOK_Info \
            "openclaw nicht im PATH."
    fi

    if command -v node >/dev/null 2>&1; then
        printf 'node: '
        node --version 2>/dev/null || printf 'Version nicht lesbar\n'
    else
        printf 'node: nicht gefunden\n'
    fi

    if command -v npm >/dev/null 2>&1; then
        printf 'npm:  '
        npm --version 2>/dev/null || printf 'Version nicht lesbar\n'
    else
        printf 'npm: nicht gefunden\n'
    fi
}

# -----------------------------------------------------------------------------
# Scan: Python und Venvs
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Python_Venv() {
    KI_Studio_LOK_Section "5. PYTHON UND VENV"

    if command -v python3 >/dev/null 2>&1; then
        printf 'python3: '
        python3 --version 2>/dev/null ||
            printf 'Version nicht lesbar\n'
    else
        printf 'python3: nicht gefunden\n'
    fi

    if command -v pip3 >/dev/null 2>&1; then
        printf 'pip3:    '
        pip3 --version 2>/dev/null ||
            printf 'Version nicht lesbar\n'
    else
        printf 'pip3: nicht gefunden\n'
    fi

    local KI_STUDIO_VENV_COUNT
    KI_STUDIO_VENV_COUNT="$(
        KI_Studio_LOK_Count_Venvs
    )"

    KI_Studio_LOK_Info \
        "Gefundene venvs: $KI_STUDIO_VENV_COUNT"
    KI_Studio_LOK_Info \
        "Nur Anzahl erfasst; venvs werden nicht bewertet."
}

# -----------------------------------------------------------------------------
# Scan: Bash, Desktop, Autostart, Systemd und Cron
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Integration() {
    KI_Studio_LOK_Section \
        "6. BASH, DESKTOP, AUTOSTART, SYSTEMD UND CRON"

    local KI_STUDIO_FILE
    local KI_STUDIO_DIR

    printf '\nBash-Integration:\n'

    for KI_STUDIO_FILE in \
        "$HOME/.bashrc" \
        "$HOME/.profile"
    do
        if [[ -f "$KI_STUDIO_FILE" ]] &&
           grep -qi \
               -E 'KI_Studio|ollama|/mnt/KI_Studio' \
               "$KI_STUDIO_FILE" 2>/dev/null; then
            KI_Studio_LOK_Info \
                "$(basename "$KI_STUDIO_FILE") enthält relevante Einträge."
        fi
    done

    printf '\nDesktop-Starter und Autostart:\n'

    for KI_STUDIO_DIR in \
        "$HOME/.local/share/applications" \
        "$HOME/.config/autostart"
    do
        [[ -d "$KI_STUDIO_DIR" ]] || continue

        while IFS= read -r -d '' KI_STUDIO_FILE; do
            if grep -qi \
                -E 'KI_Studio|ollama|/mnt/KI_Studio' \
                "$KI_STUDIO_FILE" 2>/dev/null; then

                if [[ "$KI_STUDIO_DIR" == *"/autostart" ]]; then
                    KI_Studio_LOK_Info \
                        "Autostart: $(basename "$KI_STUDIO_FILE")"
                else
                    KI_Studio_LOK_Info \
                        "Desktop: $(basename "$KI_STUDIO_FILE")"
                fi
            fi
        done < <(
            find "$KI_STUDIO_DIR" \
                -maxdepth 1 \
                -type f \
                \( -name '*.desktop' -o -name '*.sh' \) \
                -print0 2>/dev/null
        )
    done

    printf '\nUser-Systemd:\n'

    if command -v systemctl >/dev/null 2>&1; then
        local KI_STUDIO_SYSTEMD_RESULT

        KI_STUDIO_SYSTEMD_RESULT="$(
            systemctl --user list-units \
                --all \
                --type=service \
                --no-legend \
                --no-pager 2>/dev/null |
                grep -Ei \
                    'KI.?Studio|ollama|openclaw' |
                grep -v '\.device' ||
                true
        )"

        if [[ -n "$KI_STUDIO_SYSTEMD_RESULT" ]]; then
            printf '%s\n' "$KI_STUDIO_SYSTEMD_RESULT"
        else
            KI_Studio_LOK_Info \
                "Keine relevanten laufenden User-Services."
        fi

        KI_STUDIO_SYSTEMD_RESULT="$(
            systemctl --user list-unit-files \
                --no-legend \
                --no-pager 2>/dev/null |
                grep -Ei \
                    'KI.?Studio|ollama|openclaw' |
                grep -v '\.device' ||
                true
        )"

        if [[ -n "$KI_STUDIO_SYSTEMD_RESULT" ]]; then
            printf '%s\n' "$KI_STUDIO_SYSTEMD_RESULT"
        else
            KI_Studio_LOK_Info \
                "Keine relevanten User-Units registriert."
        fi
    else
        KI_Studio_LOK_Info \
            "systemctl nicht verfügbar."
    fi

    printf '\nCron:\n'

    if command -v crontab >/dev/null 2>&1; then
        local KI_STUDIO_CRON_RESULT

        KI_STUDIO_CRON_RESULT="$(
            crontab -l 2>/dev/null |
                grep -Ei 'KI.?Studio|ollama|openclaw' |
                head -n 10 ||
                true
        )"

        if [[ -n "$KI_STUDIO_CRON_RESULT" ]]; then
            printf '%s\n' "$KI_STUDIO_CRON_RESULT"
        else
            KI_Studio_LOK_Info \
                "Keine relevanten Cron-Einträge."
        fi
    else
        KI_Studio_LOK_Info \
            "crontab nicht verfügbar."
    fi
}

# -----------------------------------------------------------------------------
# Scan: Sicherheitswerkzeuge
# -----------------------------------------------------------------------------

KI_Studio_LOK_Scan_Security() {
    KI_Studio_LOK_Section "7. SICHERHEITSWERKZEUGE"

    if command -v firejail >/dev/null 2>&1; then
        KI_Studio_LOK_Info \
            "Firejail-Werkzeug vorhanden: $(firejail --version 2>/dev/null | head -n 1)"
    else
        KI_Studio_LOK_Info \
            "Firejail-Werkzeug nicht installiert."
    fi

    if command -v apparmor_parser >/dev/null 2>&1; then
        KI_Studio_LOK_Info \
            "AppArmor-Werkzeug vorhanden."
    else
        KI_Studio_LOK_Info \
            "AppArmor-Werkzeug nicht erkannt."
    fi

    if command -v systemctl >/dev/null 2>&1 &&
       systemctl is-active ufw >/dev/null 2>&1; then
        KI_Studio_LOK_Info \
            "UFW-Systemdienst aktiv."
    else
        KI_Studio_LOK_Info \
            "UFW-Systemdienst inaktiv oder nicht installiert."
    fi
}

# -----------------------------------------------------------------------------
# Deterministische Summary
# -----------------------------------------------------------------------------

KI_Studio_LOK_Generate_Summary() {
    [[ "$KI_STUDIO_REPORT_MODE" == true ]] || return 0

    local KI_STUDIO_OLLAMA_COUNT
    local KI_STUDIO_VENV_COUNT
    local KI_STUDIO_DF_INFO
    local KI_STUDIO_PYTHON_VERSION
    local KI_STUDIO_OLLAMA_STATUS
    local KI_STUDIO_FIREJAIL_STATUS
    local KI_STUDIO_UFW_STATUS
    local KI_STUDIO_SUMMARY_TEXT

    KI_STUDIO_OLLAMA_COUNT="$(
        KI_Studio_LOK_Count_Ollama_Processes
    )"

    KI_STUDIO_VENV_COUNT="$(
        KI_Studio_LOK_Count_Venvs
    )"

    KI_STUDIO_DF_INFO="$(
        df -hT "$KI_STUDIO_ROOT" 2>/dev/null |
            awk 'NR == 2 {
                print "Typ:", $2,
                      "| Größe:", $3,
                      "| Belegt:", $4,
                      "| Frei:", $5,
                      "| Auslastung:", $6
            }'
    )"

    [[ -n "$KI_STUDIO_DF_INFO" ]] ||
        KI_STUDIO_DF_INFO="nicht verfügbar"

    if command -v python3 >/dev/null 2>&1; then
        KI_STUDIO_PYTHON_VERSION="$(
            python3 --version 2>/dev/null |
                awk '{print $2}'
        )"
    else
        KI_STUDIO_PYTHON_VERSION="nicht gefunden"
    fi

    if command -v ollama >/dev/null 2>&1; then
        KI_STUDIO_OLLAMA_STATUS="PATH vorhanden"
    else
        KI_STUDIO_OLLAMA_STATUS="nicht im PATH"
    fi

    if command -v firejail >/dev/null 2>&1; then
        KI_STUDIO_FIREJAIL_STATUS="Werkzeug vorhanden"
    else
        KI_STUDIO_FIREJAIL_STATUS="nicht installiert"
    fi

    if command -v systemctl >/dev/null 2>&1 &&
       systemctl is-active ufw >/dev/null 2>&1; then
        KI_STUDIO_UFW_STATUS="Systemdienst aktiv"
    else
        KI_STUDIO_UFW_STATUS="inaktiv oder nicht installiert"
    fi

    KI_STUDIO_SUMMARY_TEXT=$(
        cat <<EOF
=== KI_STUDIO_LOK_SUMMARY ===
Zeitpunkt: $KI_STUDIO_TIMESTAMP
Root: $KI_STUDIO_ROOT
Dateisystem: $KI_STUDIO_DF_INFO

OLLAMA:
- $KI_STUDIO_OLLAMA_STATUS
- Laufende Prozesse: $KI_STUDIO_OLLAMA_COUNT

PYTHON UND VENV:
- Python: $KI_STUDIO_PYTHON_VERSION
- Gefundene venvs: $KI_STUDIO_VENV_COUNT
- Es wurde nur die Anzahl erfasst.

SICHERHEITSWERKZEUGE:
- Firejail: $KI_STUDIO_FIREJAIL_STATUS
- UFW: $KI_STUDIO_UFW_STATUS

DRILLDOWN-ABSCHNITTE IM VOLLBERICHT:
[1] KI_Studio-Root, Mount und Belegung
[2] Architektur und ORC/LOK
[3] Ollama
[4] OpenClaw und Node/npm
[5] Python und venv-Anzahl
[6] Bash, Desktop, Autostart, Systemd und Cron
[7] Sicherheitswerkzeuge

HINWEIS:
Diese Summary ist deterministisch erzeugt und nicht KI-generiert.
Vor externer Weitergabe bitte manuell prüfen.
Bekannte einfache ENV-Secret-Muster wurden maskiert.

Vollständiger Bericht:
$KI_STUDIO_REPORT_FILE
EOF
    )

    KI_Studio_LOK_Section "8. KI_STUDIO_LOK_SUMMARY"
    printf '%s\n' "$KI_STUDIO_SUMMARY_TEXT"

    if [[ -n "$KI_STUDIO_SUMMARY_FILE" ]]; then
        printf '%s\n' "$KI_STUDIO_SUMMARY_TEXT" \
            > "$KI_STUDIO_SUMMARY_FILE" 2>/dev/null ||
            KI_Studio_LOK_Warn \
                "Summary-Datei konnte nicht gespeichert werden."

        KI_Studio_LOK_OK \
            "Summary gespeichert: $KI_STUDIO_SUMMARY_FILE"
    fi
}

# -----------------------------------------------------------------------------
# Hauptablauf
# -----------------------------------------------------------------------------

main() {
    KI_Studio_LOK_Init_Report

    KI_Studio_LOK_Section "KI_STUDIO READ-ONLY SENSOR"

    printf 'Scanner: KI_Studio_LOK_Scan.sh (vC.3)\n'
    printf 'Zeit:    %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S %Z')"

    if [[ "$KI_STUDIO_REPORT_MODE" == true ]]; then
        printf 'Modus:   REPORT nach Zustimmung\n'
        printf '%s\n' \
            'Hinweis: Der Scan liest; nur Reportdateien werden gespeichert.'
    else
        printf 'Modus:   TERMINAL ONLY\n'
        printf '%s\n' \
            'Hinweis: Keine Dateien werden erzeugt oder verändert.'
    fi

    printf '%s\n' \
        'READ-ONLY: Keine Systemänderungen.'

    KI_Studio_LOK_Scan_Root
    KI_Studio_LOK_Scan_Architecture
    KI_Studio_LOK_Scan_Ollama
    KI_Studio_LOK_Scan_OpenClaw_Node
    KI_Studio_LOK_Scan_Python_Venv
    KI_Studio_LOK_Scan_Integration
    KI_Studio_LOK_Scan_Security
    KI_Studio_LOK_Generate_Summary

    KI_Studio_LOK_Section "SCAN BEENDET"

    printf '%s\n' \
        'Fertig. Das Terminal bleibt zum Kopieren geöffnet.'
    printf '%s\n' \
        'Fenster schließen oder Strg+C verwenden.'

    trap 'exit 0' INT TERM

    # Hält das bei Doppelklick geöffnete Terminal offen.
    tail -f /dev/null
}

main "$@"
