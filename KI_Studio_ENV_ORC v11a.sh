#!/bin/bash
# KI_Studio Terminal-Persistent + Zenity Fallback
# Adapted v11 -> v11a (includes Podman/Docker detection, fixes, USB-install helper)
# Date: 2026-04-05

set -euo pipefail
IFS=$'\n\t'

# --- Early terminal wrapper to keep behavior from original ---
# FIX: forward arguments correctly into the spawned terminal
if [[ -z "${KI_STUDIO_TERMINAL:-}" ]]; then
    export KI_STUDIO_TERMINAL=1
    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal --title="KI_Studio_ENV_ORC v11a" \
            -- bash -lic 'clear; echo "=== KI_Studio_ENV_ORC v11a ==="; "$@"; rc=$?; echo; echo "Drücke ENTER zum Beenden..."; read -r; exit $rc' \
            KI_Studio_ENV_ORC "$0" "$@"
        exit $?
    fi
fi

SCRIPT_NAME="$(basename "$0")"
LOCKFILE="/tmp/${SCRIPT_NAME}.lock"
LOGDIR="$HOME/.KI_Studio_home/logs"
LOGFILE="$LOGDIR/env_orc_$(date +%Y%m%d).log"

# =============================================================================
# FLAGS / DEFAULTS
# =============================================================================
DRY_RUN=false
FORCE=false
VERBOSE=false

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTION]
  -d --dry-run    Test-Modus (rsync --dry-run)
  -f --force      Bestätigungen überspringen
  -v --verbose    Detaillierte Logs
  -h --help       Hilfe
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run) DRY_RUN=true; shift ;;
        -f|--force) FORCE=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) break ;;
    esac
done

# =============================================================================
# LOCK & CLEANUP (robust)
# =============================================================================
cleanup() { rm -f "$LOCKFILE" || true; }
trap cleanup EXIT INT TERM

exec 200>"$LOCKFILE" || { echo "❌ Cannot open lockfile $LOCKFILE" >&2; exit 1; }
flock -n 200 || { echo "❌ $SCRIPT_NAME läuft bereits (lockfile)"; exit 1; }

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================
need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "❌ Benötigtes Kommando fehlt: $1" >&2
        exit 1
    }
}

for c in lsblk blkid sudo findmnt rsync jq systemctl findmnt; do
    need_cmd "$c"
done
# zenity optional

# =============================================================================
# LOGGING
# =============================================================================
mkdir -p "$LOGDIR"
log() {
    local lvl="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf "[%s] [%s] %s\n" "$ts" "$lvl" "$msg" | tee -a "$LOGFILE" >&2
    $VERBOSE && printf "  → %s\n" "$msg" >&2
}

# =============================================================================
# DRY-RUN RUNNER (FIX: DRY_RUN must not do destructive actions)
# =============================================================================
run() {
    if $DRY_RUN; then
        log "DRY" "DRY-RUN: $*"
        return 0
    fi
    "$@"
}

# =============================================================================
# BASE PATHS
# =============================================================================
KI_MOUNT_BASE="/mnt/KI_Studio"
HOME_NS="$HOME/.KI_Studio_home"
HOME_CFG="$HOME_NS/config"
HOME_PROFILED="$HOME_NS/profile.d"
HOME_LOGS="$HOME_NS/logs"
HOME_STATE="$HOME_NS/state"
HOME_ENV_HOME="$HOME_NS/KI_Studio_ENV"
HOME_DOCKER_HOME="$HOME_NS/KI_Studio_Docker"

MOUNT_CONF="$HOME_CFG/ki_studio_mount.conf"
UUID_CONF="$HOME_CFG/ki_studio_uuid.conf"
OS_MIRROR_TARGET="$KI_MOUNT_BASE/KI_Studio_OS_home"

# =============================================================================
# UI HELPERS
# =============================================================================
has_zenity() { command -v zenity >/dev/null 2>&1; }

escape_html() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

ui_info() {
    local msg="$1"
    log "INF" "$msg"
    printf "\nℹ️  %s\n\n" "$msg"
    if has_zenity; then
        zenity --info --width=520 --height=260 --text="$(echo "$msg" | escape_html)" || true
    fi
}

ui_error() {
    local msg="$1"
    log "ERR" "$msg"
    printf "\n❌ %s\n\n" "$msg" >&2
    if has_zenity; then
        zenity --error --width=520 --height=260 --text="$(echo "$msg" | escape_html)" || true
    fi
}

ui_question() {
    local msg="$1"
    # FIX: DRY_RUN must NOT auto-approve
    [[ $FORCE == true ]] && { log "ASK" "AUTO(FORCE): $msg → yes"; return 0; }

    log "ASK" "$msg"
    if has_zenity; then
        if zenity --question --width=520 --height=260 --text="$(echo "$msg" | escape_html)"; then
            return 0
        else
            return 1
        fi
    else
        printf "%s [j/N]: " "$msg" >&2
        local ans; read -r ans
        [[ "$ans" =~ ^[jJyY]$ ]]
    fi
}

ui_input() {
    local prompt="$1" default="${2:-}"
    log "ASK" "Input: $prompt [$default]"
    if has_zenity; then
        zenity --entry --width=520 --height=260 --text="$prompt" --entry-text="$default" || echo "$default"
    else
        printf "%s [%s]: " "$prompt" "$default"
        local out; read -r out
        echo "${out:-$default}"
    fi
}

# =============================================================================
# HELPERS (missing from original)
# =============================================================================
get_mountpoint_for_device() {
    # Accepts device path like /dev/sdb1 or UUID=...
    local dev="$1"
    findmnt -nr -o TARGET -S "$dev" 2>/dev/null || true
}

detect_container_engine() {
    # prefer rootless podman if available, otherwise docker if active
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
    elif systemctl is-active --quiet docker 2>/dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

# =============================================================================
# HOME NAMESPACE (auto profile loader)
# =============================================================================
ensure_home_namespace() {
    mkdir -p "$HOME_CFG" "$HOME_PROFILED" "$HOME_LOGS" "$HOME_STATE" "$HOME_ENV_HOME" "$HOME_DOCKER_HOME"
    mkdir -p "$HOME_NS"/{config,profile.d,logs,state,KI_Studio_ENV,KI_Studio_Docker}

    # Auto-profile loader for login and interactive shells
    local loader_snippet='for f in "$HOME/.KI_Studio_home/profile.d/"*.sh; do [ -r "$f" ] && . "$f"; done'
    if ! grep -q "KI_Studio_home/profile.d" "$HOME/.profile" 2>/dev/null; then
        printf "\n# KI_Studio loader\n%s\n" "$loader_snippet" >> "$HOME/.profile"
        ui_info "KI_Studio-Loader in ~/.profile eingefügt"
    fi
    if ! grep -q "KI_Studio_home/profile.d" "$HOME/.bashrc" 2>/dev/null; then
        printf "\n# KI_Studio loader\n%s\n" "$loader_snippet" >> "$HOME/.bashrc"
        ui_info "KI_Studio-Loader in ~/.bashrc eingefügt"
    fi
}

cleanup_legacy_home() {
    local legacy1="$HOME/.ki_studio_home"
    local legacy2="$HOME/.ki_studio_config"
    [[ -d "$legacy1" || -d "$legacy2" ]] && {
        ui_info "Legacy-Verzeichnisse gefunden: $legacy1, $legacy2"
        if ui_question "Entfernen?"; then
            if $DRY_RUN; then
                log "DRY" "DRY-RUN: würde entfernen: $legacy1 $legacy2"
            else
                rm -rf "$legacy1" "$legacy2"
                ui_info "Legacy entfernt"
            fi
        fi
    }
}

# =============================================================================
# MOUNT MANAGEMENT
# =============================================================================
load_mount_conf() {
    [[ -f "$MOUNT_CONF" ]] || return 1
    source "$MOUNT_CONF"
    [[ -n "${KI_DEVICE:-}" && -n "${KI_UUID:-}" && -n "${KI_ROOT:-}" ]]
}

write_mount_conf() {
    local dev="$1" uuid="$2" root="$3"
    umask 077
    mkdir -p "$(dirname "$MOUNT_CONF")"
    cat >"$MOUNT_CONF" <<EOF
KI_DEVICE="$dev"
KI_UUID="$uuid"
KI_ROOT="$root"
EOF
    echo "$uuid" >"$UUID_CONF"
    log "INF" "Mount-Konfig geschrieben: $MOUNT_CONF"
}

backup_fstab() {
    local ts="/etc/fstab.$(date +%Y%m%d_%H%M%S).ki_studio.bak"
    run sudo cp /etc/fstab "$ts"
    log "INF" "fstab backup: $ts"
}

write_fstab_entry() {
    local uuid="$1" mp="$2"
    if grep -q "$uuid" /etc/fstab 2>/dev/null; then
        log "INF" "fstab bereits enthält $uuid"
        return 0
    fi

    if $DRY_RUN; then
        log "DRY" "DRY-RUN: würde fstab Eintrag hinzufügen: UUID=$uuid -> $mp"
        return 0
    fi

    backup_fstab
    echo "UUID=$uuid  $mp  auto  defaults,nofail  0  2" | sudo tee -a /etc/fstab >/dev/null
    log "INF" "fstab entry hinzugefügt für $uuid -> $mp"
}

mount_ki_drive() {
    local dev uuid mp current_mp
    dev="$1"; uuid="$2"; mp="$KI_MOUNT_BASE"

    current_mp=$(get_mountpoint_for_device "$dev")
    [[ -n "$current_mp" && "$current_mp" != "$mp" ]] && {
        ui_question "Device ist aktuell gemountet unter $current_mp. Umount und unter $mp mounten?" && run sudo umount "$current_mp"
    }

    if [[ ! -d "$mp" ]]; then
        ui_question "Mountpoint $mp existiert nicht. Erstellen?" && {
            run sudo mkdir -p "$mp"
            run sudo chown "$(whoami)":"$(whoami)" "$mp"
        }
    fi

    if $DRY_RUN; then
        log "DRY" "DRY-RUN: würde mount konfigurieren und mounten: UUID=$uuid -> $mp (mount -a)"
        # keine Mount-Verifikation im Dry-Run
        echo "$mp"
        return 0
    fi

    write_fstab_entry "$uuid" "$mp"
    run sudo mount -a
    if [[ "$(get_mountpoint_for_device "$dev")" != "$mp" ]]; then
        ui_error "Mount fehlgeschlagen"
        return 1
    fi
    echo "$mp"
}

# =============================================================================
# KI STUDIO STRUCTURE
# =============================================================================
ensure_ki_root_structure() {
    local root="${1:-$KI_MOUNT_BASE}"

    mkdir -p "$root"/{KI_Studio_ENV,KI_Studio_Ollama,KI_Studio_OpenClaw,KI_Studio_OS_home}
    mkdir -p "$root/KI_Studio"/{KI_Studio_Tools,KI_Studio_Models,KI_Studio_Data,KI_Studio_Logs,KI_Studio_Config,KI_Studio_Cache,KI_Studio_Runtime,KI_Studio_Plugins}
    log "INF" "Atomare Struktur unter $root angelegt/prüft"
}

# =============================================================================
# GLOBAL ENV WRITER
# =============================================================================
write_global_env() {
    local root="${1:-$KI_MOUNT_BASE}"
    local env_file="$root/KI_Studio_ENV/KI_Studio_ENV.sh"
    local loader="$HOME_PROFILED/KI_Studio_home_ENV_loader.sh"

    mkdir -p "$(dirname "$env_file")"
    cat >"$env_file" <<EOF
export KI_STUDIO_ROOT="$root"
export KI_STUDIO_ENV_ROOT="\$KI_STUDIO_ROOT/KI_Studio_ENV"
export KI_STUDIO_OLLAMA="\$KI_STUDIO_ROOT/KI_Studio_Ollama"
export KI_STUDIO_OPENCLAW="\$KI_STUDIO_ROOT/KI_Studio_OpenClaw"
export KI_STUDIO_CONTAINER="\$KI_STUDIO_ROOT/KI_Studio"

export KI_STUDIO_TOOLS="\$KI_STUDIO_CONTAINER/KI_Studio_Tools"
export KI_STUDIO_MODELS="\$KI_STUDIO_CONTAINER/KI_Studio_Models"
export KI_STUDIO_DATA="\$KI_STUDIO_CONTAINER/KI_Studio_Data"
export KI_STUDIO_CONFIG="\$KI_STUDIO_CONTAINER/KI_Studio_Config"
export KI_STUDIO_CACHE="\$KI_STUDIO_CONTAINER/KI_Studio_Cache"

# XDG-Redirect
export XDG_DATA_HOME="\$KI_STUDIO_DATA"
export XDG_CONFIG_HOME="\$KI_STUDIO_CONFIG"
export XDG_CACHE_HOME="\$KI_STUDIO_CACHE"
EOF

    mkdir -p "$(dirname "$loader")"
    cat >"$loader" <<EOF
if mountpoint -q "$root" && [[ -r "$env_file" ]]; then . "$env_file"; fi
EOF
    chmod 600 "$env_file" || true
    log "INF" "ENV generiert: $env_file"
}

# =============================================================================
# OS MIRROR / SYNC
# =============================================================================
sync_os_mirror() {
    load_mount_conf || { ui_error "Mount-Konfig nicht geladen. Bitte mounten."; return 1; }
    local root="$KI_ROOT"
    mountpoint -q "$root" || { ui_error "KI_ROOT ($root) nicht gemountet"; return 1; }

    local target="$root/KI_Studio_OS_home"
    mkdir -p "$target"

    local RSYNC_OPTS=(-a --checksum)
    $DRY_RUN && RSYNC_OPTS+=(-n)

    # FIX: ensure target subdirectories exist (rsync otherwise may fail with set -e)
    mkdir -p \
        "$target/home_KI_Studio_home" \
        "$target/etc_KI_Studio_home" \
        "$target/usr_bin_KI_Studio_home" \
        "$target/usr_local_bin_KI_Studio_home" \
        "$target/usr_share_applications"

    [[ -d "$HOME_NS" ]] && rsync "${RSYNC_OPTS[@]}" --delete "$HOME_NS/" "$target/home_KI_Studio_home/" && log "INF" "Home-Sync OK"
    [[ -d /etc/KI_Studio_home ]] && rsync "${RSYNC_OPTS[@]}" --delete /etc/KI_Studio_home/ "$target/etc_KI_Studio_home/" && log "INF" "etc-Sync OK"

    # FIX: /usr/bin/KI_Studio_home may be a file/symlink (not a directory)
    if [[ -d /usr/bin/KI_Studio_home ]]; then
        rsync "${RSYNC_OPTS[@]}" --delete /usr/bin/KI_Studio_home/ "$target/usr_bin_KI_Studio_home/" && log "INF" "usr/bin (dir) OK"
    elif [[ -e /usr/bin/KI_Studio_home ]]; then
        rsync "${RSYNC_OPTS[@]}" /usr/bin/KI_Studio_home "$target/usr_bin_KI_Studio_home/" && log "INF" "usr/bin (file) OK"
    fi

    if [[ -d /usr/local/bin/KI_Studio_home ]]; then
        rsync "${RSYNC_OPTS[@]}" --delete /usr/local/bin/KI_Studio_home/ "$target/usr_local_bin_KI_Studio_home/" && log "INF" "usr/local/bin (dir) OK"
    elif [[ -e /usr/local/bin/KI_Studio_home ]]; then
        rsync "${RSYNC_OPTS[@]}" /usr/local/bin/KI_Studio_home "$target/usr_local_bin_KI_Studio_home/" && log "INF" "usr/local/bin (file) OK"
    fi

    [[ -f /usr/share/applications/KI_Studio_home.desktop ]] && rsync "${RSYNC_OPTS[@]}" --checksum /usr/share/applications/KI_Studio_home.desktop "$target/usr_share_applications/" && log "INF" "Desktop OK"

    ui_info "✅ OS-Spiegel → $target"
}

# =============================================================================
# DOCKER / PODMAN MENU & FIX
# =============================================================================
docker_menu() {
    ui_info "Container-Engine-Menü (optional nach ENV-Setup)"
    local engine
    engine="$(detect_container_engine)"
    if [[ -z "$engine" ]]; then
        ui_info "Keine Container-Engine erkannt (Podman/Docker nicht aktiv)."
    else
        ui_info "Gefundene Engine: $engine"
    fi

    local docker_fix="$HOME_DOCKER_HOME/KI_Studio_Docker_Fix_v2.sh"
    local choice
    choice=$(ui_input "Aktion (1=Prüfen,2=Vorbereiten,3=Fixen,4=Integrieren):" "1")
    case "$choice" in
        1) if [[ -n "$engine" ]]; then $engine info || true; else ui_info "Keine Engine aktiv"; fi ;;
        2) [[ -x "$docker_fix" ]] && ui_info "Docker-Fix bereit: $docker_fix" || ui_error "Docker-Fix fehlt" ;;
        3) [[ -x "$docker_fix" ]] && run sudo bash "$docker_fix" || ui_error "Docker-Fix nicht verfügbar" ;;
        4) if [[ "$engine" == "docker" ]]; then run sudo systemctl daemon-reload && run sudo systemctl restart docker && ui_info "Docker restarted"; else ui_info "Keine systemctl Aktion für podman nötig (rootless)"; fi ;;
        *) return ;;
    esac
}

# =============================================================================
# SYSTEM SETUP (.desktop + symlink)
# =============================================================================
system_setup() {
    if $DRY_RUN; then
        log "DRY" "DRY-RUN: würde System-Setup durchführen (.desktop + /usr/bin Symlink)"
        return 0
    fi

    mkdir -p "$HOME_NS"/{config,profile.d,logs,state,KI_Studio_ENV,KI_Studio_Docker}

    sudo mkdir -p /usr/share/applications
    cat > /tmp/ki_studio.desktop <<EOF
[Desktop Entry]
Name=KI_Studio_home
Exec=/usr/bin/KI_Studio_home
Icon=applications-system
Terminal=true
Type=Application
Categories=System;AI;
Comment=KI_Studio Öko-System Manager
EOF
    sudo tee /usr/share/applications/KI_Studio_home.desktop > /dev/null < /tmp/ki_studio.desktop
    rm /tmp/ki_studio.desktop

    sudo mkdir -p /etc/KI_Studio_home
    # FIX: /usr/bin/KI_Studio_home must be a file/symlink, not a directory
    local fullpath
    fullpath="$(realpath "$0")"
    sudo ln -sf "$fullpath" /usr/bin/KI_Studio_home 2>/dev/null || true

    ui_info "✅ System-Setup (Desktop + Launcher) angelegt"
}

# =============================================================================
# INSTALL HOOKS (stubs)
# =============================================================================
install_ollama() {
    # Placeholder: implement actual install commands or container template
    local target="${1:-$KI_MOUNT_BASE/opt/ollama}"
    ui_info "Install Ollama stub -> $target"
    mkdir -p "$target"
    # Example (commented): curl -fsSL <ollama-install-url> | tar -C "$target" -xzf -
    log "INF" "OLLAMA install stub completed (customize install_ollama in script)"
}

install_openclaw() {
    local target="${1:-$KI_MOUNT_BASE/opt/openclaw}"
    ui_info "Install OpenClaw stub -> $target"
    mkdir -p "$target"
    # Example: git clone ... "$target"
    log "INF" "OPENCLAW install stub completed (customize install_openclaw in script)"
}

install_linuxbrew_prefix() {
    local prefix="${1:-$KI_MOUNT_BASE/homebrew}"
    ui_info "Homebrew prefix stub -> $prefix"
    mkdir -p "$prefix"
    # Real command example:
    # NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" -- --prefix="$prefix"
    log "INF" "LINUXBREW prefix stub completed (customize install_linuxbrew_prefix in script)"
}

# =============================================================================
# ANALYSE
# =============================================================================
analyse_env() {
    echo "============================================================"
    echo " KI_Studio ENV_ORC v11a – Analyse"
    echo "============================================================"

    load_mount_conf && echo "✓ Konfig: $KI_DEVICE → $KI_ROOT" || echo "✗ Konfig fehlt"
    mountpoint -q "$KI_MOUNT_BASE" && echo "✓ Mount: $KI_MOUNT_BASE" || echo "✗ Mount fehlt"

    echo "ENV:"
    env | grep '^KI_STUDIO_' || echo "  (keine)"

    [[ -d "$OS_MIRROR_TARGET" ]] && echo "OS-Spiegel: ✓ $OS_MIRROR_TARGET" || echo "OS-Spiegel: ✗"

    log "INF" "Analyse OK"
}

# =============================================================================
# MENU
# =============================================================================
menu() {
    if has_zenity; then
        zenity --list --radiolist=TRUE --width=650 --height=480 \
            --title="KI_Studio_ENV_ORC v11a" --text="Aktion:" \
            TRUE "1. Analyse" \
            FALSE "2. Setup/Reparatur" \
            FALSE "3. OS-Spiegel-Sync" \
            FALSE "4. Docker-Menü" \
            FALSE "5. System-Setup" \
            FALSE "6. Vollständiges Setup" \
            FALSE "7. Install Hooks (ollama/openclaw/homebrew)" \
            FALSE "8. USB-Install: copy script to /mnt/KI_Studio/bin-stubs" \
            FALSE "Quit"
    else
        echo "1) Analyse      4) Docker-Menü"
        echo "2) Setup        5) System-Setup"
        echo "3) OS-Spiegel   6) Voll-Setup"
        echo "7) Install Hooks  8) USB-Install copy"
        echo "9) Quit"
        read -rp "→ " choice
        echo "${choice:-1}"
    fi
}

# =============================================================================
# USB / BIN-STUBS INSTALLER (creates /mnt/KI_Studio/bin-stubs and copy script)
# =============================================================================
usb_install_copy_self() {
    # Offer to create /mnt/KI_Studio/bin-stubs and copy this script there, with exec bit.
    local target_dir="$KI_MOUNT_BASE/bin-stubs"

    # FIX: prevent writing to OS disk when not mounted
    mountpoint -q "$KI_MOUNT_BASE" || { ui_error "$KI_MOUNT_BASE ist nicht gemountet. Abbruch."; return 1; }

    if [[ -d "$target_dir" ]]; then
        ui_info "$target_dir existiert bereits."
    else
        ui_question "Erstelle $target_dir ?" || return 1
        run sudo mkdir -p "$target_dir"
        run sudo chown "$(whoami)":"$(whoami)" "$target_dir"
        ui_info "Erstellt: $target_dir"
    fi

    local dest="$target_dir/$SCRIPT_NAME"
    if $DRY_RUN; then
        log "DRY" "DRY-RUN: würde kopieren: $0 -> $dest"
    else
        cp -f "$0" "$dest"
        chmod +x "$dest"
        ui_info "Kopie erstellt: $dest"
    fi

    # Optionally create a small wrapper in /usr/bin for easy launching if desired
    ui_question "Symlink /usr/bin/KI_Studio_home auf $dest erstellen?" && run sudo ln -sf "$dest" /usr/bin/KI_Studio_home
}

# =============================================================================
# SETUP / REPAIR (placeholder: combine steps)
# =============================================================================
setup_or_repair() {
    ui_info "Setup/Reparatur gestartet (DryRun=$DRY_RUN)"

    # FIX: don't write to /mnt/KI_Studio when not mounted (prevents OS-disk pollution)
    mountpoint -q "$KI_MOUNT_BASE" || { ui_error "$KI_MOUNT_BASE ist nicht gemountet. Bitte zuerst mounten."; return 1; }

    if $DRY_RUN; then
        log "DRY" "DRY-RUN: würde Struktur + ENV schreiben unter $KI_MOUNT_BASE"
        ui_info "Setup/Reparatur (DRY-RUN) abgeschlossen (keine Änderungen geschrieben)"
        return 0
    fi

    ensure_ki_root_structure "$KI_MOUNT_BASE"
    write_global_env "$KI_MOUNT_BASE"
    ui_info "Setup/Reparatur abgeschlossen (prüfe Logs)"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    ensure_home_namespace
    cleanup_legacy_home

    log "INF" "KI_Studio_ENV_ORC v11a gestartet (dry=$DRY_RUN force=$FORCE)"

    while true; do
        choice=$(menu || echo "Quit")
        case "$choice" in
            "1. Analyse"|"1") analyse_env ;;
            "2. Setup/Reparatur"|"2") setup_or_repair ;;
            "3. OS-Spiegel-Sync"|"3") sync_os_mirror ;;
            "4. Docker-Menü"|"4") docker_menu ;;
            "5. System-Setup"|"5") system_setup ;;
            "6. Vollständiges Setup"|"6") {
                system_setup
                setup_or_repair
                sync_os_mirror
                docker_menu
                ui_info "🎉 v11a Vollständig!"
            } ;;
            "7. Install Hooks (ollama/openclaw/homebrew)"|"7") {
                ui_question "Install Ollama?" && install_ollama "$KI_MOUNT_BASE/opt/ollama"
                ui_question "Install OpenClaw?" && install_openclaw "$KI_MOUNT_BASE/opt/openclaw"
                ui_question "Install Linuxbrew prefix?" && install_linuxbrew_prefix "$KI_MOUNT_BASE/homebrew"
            } ;;
            "8. USB-Install: copy script to /mnt/KI_Studio/bin-stubs"|"8") usb_install_copy_self ;;
            "Quit"|"9") log "INF" "Beende v11a"; exit 0 ;;
            *) # numeric fallback from non-zenity menu
                case "$choice" in
                    1) analyse_env ;;
                    2) setup_or_repair ;;
                    3) sync_os_mirror ;;
                    4) docker_menu ;;
                    5) system_setup ;;
                    6) setup_or_repair; sync_os_mirror; docker_menu ;;
                    7) install_ollama "$KI_MOUNT_BASE/opt/ollama"; install_openclaw "$KI_MOUNT_BASE/opt/openclaw" ;;
                    8) usb_install_copy_self ;;
                    9) log "INF" "Beende v11a"; exit 0 ;;
                    *) log "ERR" "Unknown choice: $choice" ;;
                esac
                ;;
        esac
    done
}

main "$@"
