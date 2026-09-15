#!/usr/bin/env bash
# KI_Studio_Inventory_Scan.sh
# Transparente, Dialog-gesteuerte Bestandsaufnahme
# 
# PRINZIPIEN:
#   - Terminal ist die Standardausgabe (nichts wird ohne Frage geschrieben)
#   - Dialog-Kaskade: YAD (grafisch) → zenity → read (Terminal-Fallback)
#   - Wenn gespeichert: nur /mnt/KI_Studio/KI_Studio_Logs/
#   - Benutzer sieht GENAU, was das Script tun will, BEVOR es das tut

set -u
umask 077

# ════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ════════════════════════════════════════════════════════════════════

KI_BASE="/mnt/KI_Studio"
LOG_BASE="${KI_BASE}/KI_Studio_Logs"
INVENTORY_LOG_DIR="${LOG_BASE}/KI_Studio_Inventory"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ════════════════════════════════════════════════════════════════════
# HILFSFUNKTIONEN
# ════════════════════════════════════════════════════════════════════

# Dialog mit Kaskade: YAD → zenity → Terminal
dialog_question() {
    local question="$1"
    local default="${2:-no}"  # yes oder no
    
    # Versuchen: YAD (grafisch)
    if command -v yad >/dev/null 2>&1; then
        yad --question --title="KI_Studio Inventory" --text="$question" \
            --width=500 --height=150 2>/dev/null
        return $?
    fi
    
    # Fallback: zenity
    if command -v zenity >/dev/null 2>&1; then
        zenity --question --title="KI_Studio Inventory" --text="$question" \
            --width=500 --height=150 2>/dev/null
        return $?
    fi
    
    # Fallback: Terminal
    local prompt="$question (j/n) [${default}]: "
    read -p "$prompt" -r response
    
    case "${response,,}" in
        j|ja|yes)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Sichere Verzeichnis-Erstellung (mit Transparenz)
ensure_log_dir() {
    if [[ ! -d "$INVENTORY_LOG_DIR" ]]; then
        echo "📁 Erstelle Logverzeichnis: $INVENTORY_LOG_DIR"
        mkdir -p "$INVENTORY_LOG_DIR" 2>/dev/null || {
            echo "❌ FEHLER: Konnte Verzeichnis nicht erstellen!"
            echo "   Grund: Keine Schreibrechte auf $LOG_BASE"
            return 1
        }
    fi
}

# Info vor Speichern anzeigen
show_save_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 SPEICHERN: Datei wird hier abgelegt:"
    echo "   $INVENTORY_LOG_DIR/KI_Studio_${1}_${TIMESTAMP}.csv"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ════════════════════════════════════════════════════════════════════
# GANZ OBEN: FRAGE ZUM SPEICHERN
# ════════════════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          KI_Studio Inventory Scan                              ║"
echo "║                                                                ║"
echo "║  Transparentes Scanning-Werkzeug                               ║"
echo "║  • Ausgabe läuft immer im Terminal                             ║"
echo "║  • Optionale Speicherung in /mnt/KI_Studio/KI_Studio_Logs/    ║"
echo "║  • Keine versteckten Schreibvorgänge                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

SAVE_REPORTS=0
if dialog_question "Sollen die Ergebnisse auch gespeichert werden?\n(Speichern in: $INVENTORY_LOG_DIR/)"; then
    SAVE_REPORTS=1
    ensure_log_dir || exit 1
    echo "✅ Reports werden gespeichert."
else
    echo "ℹ️  Nur Terminal-Ausgabe. (Du kannst das Terminal kopieren.)"
fi

echo ""
echo "🔍 Scan wird gestartet..."
echo ""

# ════════════════════════════════════════════════════════════════════
# 1. VERZEICHNIS-STRUKTUR
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 1. VERZEICHNIS-STRUKTUR (bis Ebene 3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STRUCT_OUTPUT=$(tree -L 3 -h --charset ascii "$KI_BASE" 2>/dev/null \
  || find "$KI_BASE" -maxdepth 3 -type d -printf '%p\n' | sed 's|[^/]*/| |g')

echo "$STRUCT_OUTPUT"

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "Structure_L3"
    echo "$STRUCT_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Structure_L3_${TIMESTAMP}.txt"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 2. TOP-LEVEL VERZEICHNISSE MIT GRÖSSEN
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 2. GRÖßEN-ANALYSE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s | %s\n' "Größe" "Dateien" "Ordner" "Verzeichnis"
  printf '%s\n' "───────────────────────────────────────────────────────"
  
  for dir in "$KI_BASE"/*; do
    if [[ -d "$dir" ]]; then
      size=$(du -sh "$dir" 2>/dev/null | cut -f1)
      files=$(find "$dir" -maxdepth 5 -type f 2>/dev/null | wc -l)
      dirs=$(find "$dir" -maxdepth 5 -type d 2>/dev/null | wc -l)
      basename=$(basename "$dir")
      printf '%s | %5d | %5d | %s\n' "$size" "$files" "$dirs" "$basename"
    fi
  done | sort -k4
} | tee /tmp/ki_sizes_output_$$.txt

SIZE_OUTPUT=$(cat /tmp/ki_sizes_output_$$.txt)
rm -f /tmp/ki_sizes_output_$$.txt

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "Sizes"
    echo "$SIZE_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Sizes_${TIMESTAMP}.csv"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 3. SHELL-SKRIPTE CATALOGISIEREN
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 3. SHELL-SKRIPTE INVENTAR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s | %s | %s | %s\n' \
    "Pfad" "Größe" "Exec" "Zeilen" "Mtime" "Erste Funktion/Zweck"
  printf '%s\n' "──────────────────────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.sh" 2>/dev/null | while read -r script; do
    size=$(stat -c%s "$script" 2>/dev/null || echo "0")
    mtime=$(stat -c%y "$script" 2>/dev/null | cut -d' ' -f1)
    exec_flag=$(test -x "$script" && echo "✓" || echo "✗")
    lines=$(wc -l < "$script" 2>/dev/null || echo "0")
    purpose=$(grep -m1 '^#' "$script" 2>/dev/null | cut -c1-40)
    rel_path="${script#$KI_BASE/}"
    
    printf '%s | %s | %s | %4d | %s | %s\n' \
      "$rel_path" "$size" "$exec_flag" "$lines" "$mtime" "$purpose"
  done
} | tee /tmp/ki_scripts_output_$$.txt

SCRIPTS_OUTPUT=$(cat /tmp/ki_scripts_output_$$.txt)
rm -f /tmp/ki_scripts_output_$$.txt

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "ShellScripts"
    echo "$SCRIPTS_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_ShellScripts_${TIMESTAMP}.csv"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 4. KONFIGURATIONSDATEIEN
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  4. KONFIGURATIONSDATEIEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s | %s\n' "Pfad" "Typ" "Größe" "Gültig?"
  printf '%s\n' "──────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
    -o -name "*.toml" -o -name "*.conf" -o -name "*.cfg" \) 2>/dev/null | while read -r config; do
    
    size=$(stat -c%s "$config" 2>/dev/null || echo "0")
    ext="${config##*.}"
    rel_path="${config#$KI_BASE/}"
    
    valid="?"
    case "$ext" in
      json)
        jq empty "$config" 2>/dev/null && valid="✓" || valid="✗"
        ;;
      yaml|yml)
        python3 -c "import yaml; yaml.safe_load(open('$config'))" 2>/dev/null && valid="✓" || valid="✗"
        ;;
      toml)
        python3 -c "import tomllib; tomllib.loads(open('$config').read())" 2>/dev/null && valid="✓" || valid="✗"
        ;;
    esac
    
    printf '%s | %s | %s | %s\n' "$rel_path" "$ext" "$size" "$valid"
  done
} | tee /tmp/ki_configs_output_$$.txt

CONFIGS_OUTPUT=$(cat /tmp/ki_configs_output_$$.txt)
rm -f /tmp/ki_configs_output_$$.txt

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "Configs"
    echo "$CONFIGS_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Configs_${TIMESTAMP}.csv"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 5. MARKDOWN-DOKUMENTATION
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 5. MARKDOWN-DOKUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s | %s | %s\n' "Pfad" "Zeilen" "Überschriften" "Links" "Code-Blöcke"
  printf '%s\n' "────────────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.md" 2>/dev/null | while read -r mdfile; do
    lines=$(wc -l < "$mdfile" 2>/dev/null || echo "0")
    headers=$(grep -c '^#' "$mdfile" 2>/dev/null || echo "0")
    links=$(grep -cE '\[.*\]\(.*\)' "$mdfile" 2>/dev/null || echo "0")
    codeblocks=$(grep -c '^```' "$mdfile" 2>/dev/null || echo "0")
    rel_path="${mdfile#$KI_BASE/}"
    
    printf '%s | %s | %s | %s | %s\n' "$rel_path" "$lines" "$headers" "$links" "$codeblocks"
  done
} | tee /tmp/ki_markdown_output_$$.txt

MARKDOWN_OUTPUT=$(cat /tmp/ki_markdown_output_$$.txt)
rm -f /tmp/ki_markdown_output_$$.txt

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "Markdown"
    echo "$MARKDOWN_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Markdown_${TIMESTAMP}.csv"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 6. VERZEICHNIS-ZWECK-MAPPING
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗺️  6. VERZEICHNIS-ZWECK-MAPPING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s | %s | %s\n' "Verzeichnis" "Zweck" "Status" "Dateien" "Größe"
  printf '%s\n' "────────────────────────────────────────────────────────────"
  
  declare -A purposes=(
    ["KI_Studio"]="Tools, Models, Plugins, Workspaces"
    ["KI_Studio_SYS"]="System-ORC, Boot, Scan, Setup"
    ["KI_Studio_Claw_Patrol"]="Patrol Nervensystem (Ryder + 9 Rollen)"
    ["KI_Studio_Tools"]="Ollama, n8n, LM Studio, ComfyUI, etc."
    ["KI_Studio_Models"]="Modelle (GGUF, Safetensors, etc.)"
    ["KI_Studio_Docker"]="Docker Compose, Volumes, Images"
    ["KI_Studio_Runtime"]="Sockets, PID, Cache, Sessions"
    ["KI_Studio_Config"]="Konfigurationsdateien"
    ["KI_Studio_Database"]="SQLite, Metadaten"
    ["KI_Studio_Data"]="RAG, Dokumente, Datensätze"
    ["KI_Studio_Futter"]="Archive, WIP, zu verarbeiten"
    ["KI_Studio_ALT_ARCHIV"]="Alte Systemstände"
  )
  
  for dir in "$KI_BASE"/*; do
    if [[ -d "$dir" ]]; then
      dirname=$(basename "$dir")
      purpose="${purposes[$dirname]:-[UNBEKANNT]}"
      files=$(find "$dir" -maxdepth 5 -type f 2>/dev/null | wc -l)
      size=$(du -sh "$dir" 2>/dev/null | cut -f1)
      
      status="?"
      [[ $files -eq 0 ]] && status="📭 Empty"
      [[ $files -gt 0 ]] && status="✓ OK"
      [[ -f "$dir/.wip" ]] && status="⚠️  WIP"
      
      printf '%s | %s | %s | %d | %s\n' "$dirname" "$purpose" "$status" "$files" "$size"
    fi
  done
} | tee /tmp/ki_purpose_output_$$.txt

PURPOSE_OUTPUT=$(cat /tmp/ki_purpose_output_$$.txt)
rm -f /tmp/ki_purpose_output_$$.txt

if [[ $SAVE_REPORTS -eq 1 ]]; then
    show_save_info "Purpose_Map"
    echo "$PURPOSE_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Purpose_Map_${TIMESTAMP}.csv"
    echo "✅ Gespeichert."
fi

# ════════════════════════════════════════════════════════════════════
# 7. KI_STUDIO_FUTTER DETAIL-SCAN
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🍜 7. KI_STUDIO_FUTTER DETAIL-SCAN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ -d "$KI_BASE/KI_Studio_Futter" ]]; then
    {
      printf '%s | %s | %s | %s | %s\n' "Datei" "Typ" "Größe" "Mtime" "Relevanz-Hinweise"
      printf '%s\n' "────────────────────────────────────────────────────────────"
      
      find "$KI_BASE/KI_Studio_Futter" -maxdepth 3 -type f 2>/dev/null | while read -r file; do
        size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        mtime=$(stat -c%y "$file" 2>/dev/null | cut -d' ' -f1)
        ext="${file##*.}"
        basename=$(basename "$file")
        
        hints=""
        case "$ext" in
          md|txt)
            lines=$(wc -l < "$file" 2>/dev/null || echo "0")
            [[ $lines -gt 100 ]] && hints="📄 Langdoku"
            ;;
          json)
            jq empty "$file" 2>/dev/null && hints="✓ Valid JSON" || hints="✗ Invalid JSON"
            ;;
          sh|bash)
            lines=$(wc -l < "$file" 2>/dev/null || echo "0")
            [[ $lines -gt 50 ]] && hints="⚙️ Komplexes Skript"
            ;;
          html)
            hints="🌐 Gespeichert HTML"
            ;;
        esac
        
        printf '%s | %s | %s | %s | %s\n' "$basename" "$ext" "$size" "$mtime" "$hints"
      done
    } | tee /tmp/ki_futter_output_$$.txt
    
    FUTTER_OUTPUT=$(cat /tmp/ki_futter_output_$$.txt)
    rm -f /tmp/ki_futter_output_$$.txt
    
    if [[ $SAVE_REPORTS -eq 1 ]]; then
        show_save_info "Futter"
        echo "$FUTTER_OUTPUT" > "$INVENTORY_LOG_DIR/KI_Studio_Futter_${TIMESTAMP}.csv"
        echo "✅ Gespeichert."
    fi
else
    echo "[NICHT VORHANDEN] KI_Studio_Futter"
fi

# ════════════════════════════════════════════════════════════════════
# ABSCHLUSS
# ════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SCAN ABGESCHLOSSEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $SAVE_REPORTS -eq 1 ]]; then
    echo "📁 Reports gespeichert in:"
    echo "   $INVENTORY_LOG_DIR/"
    echo ""
    ls -lh "$INVENTORY_LOG_DIR"/ 2>/dev/null | tail -10
    echo ""
fi

echo "🚀 Terminal-Ausgabe kannst du dir hier kopieren oder ein neuen Tab öffnen."
echo ""
