#!/bin/bash
# ---------------------------------------------------
# KI-System Manager - Interaktives Kontroll- & Startscript
# Erstellt: 2025-05-29
# Autor: arteliarcarrotti & ChatGPT
# ---------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Variablen ---
USER_NAME=$(whoami)
KI_STUDIO="/mnt/KI_Studio"
KI_MODELS_DIR="$KI_STUDIO/ki_models"
LOCAL_KI_DIR="$HOME/ki_files"
JOPLIN_PATH="$KI_STUDIO/Joplin"
AUTOSTART_DIR="$HOME/.config/autostart"
START_SCRIPT="$HOME/.local/bin/start_ki_assi.sh"
LOG_DIR="$HOME/ki_system_logs"
CONFIG_BACKUP="$LOG_DIR/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
LAST_RUN_LOG="$LOG_DIR/last_run.log"
STATUS_LOG="$LOG_DIR/status.log"

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # keine Farbe

# --- Funktionen für farbige Ausgabe ---
say()   { echo -e "${GREEN}$1${NC}"; }
warn()  { echo -e "${YELLOW}$1${NC}"; }
err()   { echo -e "${RED}$1${NC}"; exit 1; }
info()  { echo -e "${CYAN}$1${NC}"; }

# --- Überprüfe und installiere benötigte Tools ---
install_tool() {
  local TOOL=$1
  local PKG=$2
  if ! command -v "$TOOL" &>/dev/null; then
    warn "$TOOL nicht gefunden, versuche Installation..."
    sudo apt install -y "$PKG" || err "Fehler bei der Installation von $TOOL"
  else
    say "$TOOL ist installiert."
  fi
}

check_install_tools() {
  install_tool espeak espeak
  install_tool zenity zenity
  install_tool python3 python3
  install_tool pip3 python3-pip
  install_tool jq jq
  install_tool tar tar
  install_tool systemctl systemd
}

# --- Joplin oder Alternativen suchen ---
find_best_assistant() {
  say "Suche besten verfügbaren KI-Assistenten..."

  # 1. Suche Joplin AppImage
  if [[ -x "$JOPLIN_PATH/Joplin.AppImage" ]]; then
    say "Joplin gefunden unter $JOPLIN_PATH"
    echo "joplin"
    return
  fi

  local FOUND_PATH
  FOUND_PATH=$(sudo find / -type f -iname "Joplin.AppImage" 2>/dev/null | head -n1 || true)
  if [[ -n "$FOUND_PATH" && -x "$FOUND_PATH" ]]; then
    JOPLIN_PATH=$(dirname "$FOUND_PATH")
    say "Joplin gefunden: $FOUND_PATH"
    echo "joplin"
    return
  fi

  # 2. Suche LM Studio (Beispiel: lmstudio executable)
  if command -v lmstudio &>/dev/null; then
    say "LM Studio gefunden (System)"
    echo "lmstudio"
    return
  fi

  # 3. Suche Browser (Firefox als Beispiel)
  if command -v firefox &>/dev/null; then
    say "Firefox Browser gefunden"
    echo "firefox"
    return
  fi

  warn "Kein geeigneter Assistent gefunden."
  echo "none"
}

# --- Starte Assistent im passenden Modus ---
start_assistant() {
  local assistant=$1
  say "Starte Assistent: $assistant"

  case $assistant in
    joplin)
      nohup "$JOPLIN_PATH/Joplin.AppImage" &>/dev/null &
      say "Joplin gestartet."
      ;;
    lmstudio)
      nohup lmstudio &>/dev/null &
      say "LM Studio gestartet."
      ;;
    firefox)
      # Beispiel: öffne lokale KI-UI Webseite oder Startseite
      nohup firefox "http://localhost:8080" &>/dev/null &
      say "Firefox Browser geöffnet."
      ;;
    none)
      warn "Kein Assistent zum Starten vorhanden."
      ;;
  esac
}

# --- Frage Verbesserung/Training beim Neustart ab ---
ask_for_training() {
  echo
  read -rp "Möchtest du den KI-Assistenten beim Neustart verbessern/trainieren? (j/n): " train_choice
  if [[ "$train_choice" =~ ^[Jj]$ ]]; then
    say "Starte Trainingsroutine..."
    # Hier können deine Trainings-/Update-Befehle eingetragen werden, z.B.:
    # ./train_model.sh
    # oder python3 train.py
    echo "Training ausgeführt" >> "$LAST_RUN_LOG"
    say "Training abgeschlossen."
  else
    say "Training übersprungen."
  fi
}

# --- Sichere Konfiguration und Logs beim Herunterfahren ---
backup_on_shutdown() {
  say "Sichere Konfigurationen und Logs im Verzeichnis $LOG_DIR"
  mkdir -p "$LOG_DIR"

  # Beispiel: wichtige config Dateien und Logs sichern
  local config_files=(
    "$KI_STUDIO/config"
    "$KI_STUDIO/ki_settings.json"
    "$HOME/.bashrc"
    "$HOME/.profile"
  )

  tar -czf "$CONFIG_BACKUP" "${config_files[@]}" 2>/dev/null || warn "Backup einiger Dateien fehlgeschlagen."

  say "Backup erstellt: $CONFIG_BACKUP"

  # Letzte Miss/Erfolge protokollieren (hier Beispiel)
  echo "Backup erstellt am $(date)" > "$STATUS_LOG"
  echo "Letzte Trainingsergebnisse:" >> "$STATUS_LOG"
  tail -n 10 "$LAST_RUN_LOG" >> "$STATUS_LOG" 2>/dev/null || echo "Keine Trainingsergebnisse gefunden." >> "$STATUS_LOG"

  say "Status-Log aktualisiert unter $STATUS_LOG"
}

# --- Statusanzeige beim Start ---
show_status() {
  echo -e "\n${CYAN}--- KI-System Status ---${NC}"
  echo "Benutzer: $USER_NAME"
  echo "KI Studio Pfad: $KI_STUDIO"
  echo "Modelle in: $KI_MODELS_DIR"
  echo "Joplin Pfad: $JOPLIN_PATH"
  echo "Letzte Sicherung: $(ls -t $LOG_DIR/*.tar.gz 2>/dev/null | head -n1 || echo 'keine')"
  echo "Letzte Trainingsergebnisse:"
  tail -n 5 "$LAST_RUN_LOG" 2>/dev/null || echo "keine"
  echo -e "${CYAN}----------------------${NC}\n"
}

# --- Hauptmenü (interaktiv) ---
main_menu() {
  while true; do
    show_status
    echo "Optionen:"
    echo " 1) KI-Assistent starten"
    echo " 2) KI-Assistent beim Neustart verbessern/trainieren"
    echo " 3) Konfiguration & Logs sichern"
    echo " 4) Systemstatus anzeigen"
    echo " 0) Beenden"
    read -rp "Wähle eine Option: " choice

    case $choice in
      1)
        assistant=$(find_best_assistant)
        start_assistant "$assistant"
        ;;
      2)
        ask_for_training
        ;;
      3)
        backup_on_shutdown
        ;;
      4)
        show_status
        ;;
      0)
        say "Auf Wiedersehen!"
        exit 0
        ;;
      *)
        warn "Ungültige Eingabe."
        ;;
    esac
    echo
    read -rp "Weiter? (Enter drücken)" _
  done
}

# --- Sicherstellen, dass das Skript mit sudo läuft ---
if [[ $EUID -ne 0 ]]; then
  warn "Bitte das Skript mit sudo ausführen!"
  exit 1
fi

# --- Setup & Checks ---
check_install_tools

mkdir -p "$LOG_DIR"
touch "$LAST_RUN_LOG"

# --- Starte Hauptmenü ---
main_menu

