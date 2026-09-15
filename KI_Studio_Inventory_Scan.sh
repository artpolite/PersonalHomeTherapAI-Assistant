#!/usr/bin/env bash
# KI_Studio_Inventory_Scan.sh
# Detaillierte Bestandsaufnahme des KI_Studio mit exportierbaren Reports

set -u
umask 077

KI_BASE="/mnt/KI_Studio"
REPORT_DIR="${HOME}/KI_Studio_Inventory"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

mkdir -p "$REPORT_DIR"

# ════════════════════════════════════════════════════════════════════
# 1. VERZEICHNIS-STRUKTUR
# ════════════════════════════════════════════════════════════════════

echo "📁 Struktur-Scan wird ausgeführt..."

tree -L 3 -h --charset ascii "$KI_BASE" 2>/dev/null > "$REPORT_DIR/KI_Studio_Structure_L3_${TIMESTAMP}.txt" \
  || find "$KI_BASE" -maxdepth 3 -type d -printf '%p\n' | sed 's|[^/]*/| |g' > "$REPORT_DIR/KI_Studio_Structure_L3_${TIMESTAMP}.txt"

# ════════════════════════════════════════════════════════════════════
# 2. TOP-LEVEL VERZEICHNISSE MIT GRÖSSEN
# ════════════════════════════════════════════════════════════════════

echo "📊 Größen-Analyse..."

{
  echo "KI_STUDIO TOP-LEVEL DIRECTORIES"
  echo "Größe | Dateien | Ordner | Pfad"
  echo "───────────────────────────────────────────────────────────"
  
  for dir in "$KI_BASE"/*; do
    if [[ -d "$dir" ]]; then
      size=$(du -sh "$dir" 2>/dev/null | cut -f1)
      files=$(find "$dir" -maxdepth 5 -type f 2>/dev/null | wc -l)
      dirs=$(find "$dir" -maxdepth 5 -type d 2>/dev/null | wc -l)
      basename=$(basename "$dir")
      printf '%s | %5d | %5d | %s\n' "$size" "$files" "$dirs" "$basename"
    fi
  done | sort -k4
} > "$REPORT_DIR/KI_Studio_Sizes_${TIMESTAMP}.txt"

# ════════════════════════════════════════════════════════════════════
# 3. ALLE SHELL-SKRIPTE CATALOGISIEREN
# ════════════════════════════════════════════════════════════════════

echo "🔧 Shell-Skripte werden inventarisiert..."

{
  echo "SHELL-SKRIPTE INVENTAR"
  echo "Pfad | Größe | Mtime | Executable | Zeilen | Erste Funktion/Zweck"
  echo "────────────────────────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.sh" | while read -r script; do
    size=$(stat -c%s "$script" 2>/dev/null || echo "0")
    mtime=$(stat -c%y "$script" 2>/dev/null | cut -d' ' -f1-2)
    exec_flag=$(test -x "$script" && echo "✓" || echo "✗")
    lines=$(wc -l < "$script" 2>/dev/null || echo "0")
    
    # Erste Funktion oder Kommentar extrahieren
    purpose=$(grep -m1 '^#.*' "$script" 2>/dev/null | head -c 50)
    
    rel_path="${script#$KI_BASE/}"
    printf '%s | %s | %s | %s | %4d | %s\n' \
      "$rel_path" "$size" "$mtime" "$exec_flag" "$lines" "$purpose"
  done
} > "$REPORT_DIR/KI_Studio_ShellScripts_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 4. PYTHON-DATEIEN CATALOGISIEREN
# ════════════════════════════════════════════════════════════════════

echo "🐍 Python-Dateien werden inventarisiert..."

{
  echo "PYTHON-DATEIEN INVENTAR"
  echo "Pfad | Größe | Mtime | Klassen | Funktionen | Imports"
  echo "────────────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.py" | while read -r pyfile; do
    size=$(stat -c%s "$pyfile" 2>/dev/null || echo "0")
    mtime=$(stat -c%y "$pyfile" 2>/dev/null | cut -d' ' -f1-2)
    classes=$(grep -c '^class ' "$pyfile" 2>/dev/null || echo "0")
    functions=$(grep -c '^def ' "$pyfile" 2>/dev/null || echo "0")
    imports=$(grep -c '^import\|^from' "$pyfile" 2>/dev/null || echo "0")
    
    rel_path="${pyfile#$KI_BASE/}"
    printf '%s | %s | %s | %s | %s | %s\n' \
      "$rel_path" "$size" "$mtime" "$classes" "$functions" "$imports"
  done
} > "$REPORT_DIR/KI_Studio_PythonFiles_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 5. KONFIGURATIONSDATEIEN
# ════════════════════════════════════════════════════════════════════

echo "⚙️ Konfigurationsdateien werden gescannt..."

{
  echo "KONFIGURATIONSDATEIEN"
  echo "Pfad | Typ | Größe | Gültig?"
  echo "────────────────────────────────────────"
  
  find "$KI_BASE" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
    -o -name "*.toml" -o -name "*.conf" -o -name "*.cfg" \) | while read -r config; do
    
    size=$(stat -c%s "$config" 2>/dev/null || echo "0")
    ext="${config##*.}"
    
    # Validität prüfen
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
      *)
        valid="?"
        ;;
    esac
    
    rel_path="${config#$KI_BASE/}"
    printf '%s | %s | %s | %s\n' "$rel_path" "$ext" "$size" "$valid"
  done
} > "$REPORT_DIR/KI_Studio_Configs_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 6. JSON-DATEIEN (TIEFER SCAN)
# ════════════════════════════════════════════════════════════════════

echo "📋 JSON-Struktur wird analysiert..."

{
  echo "JSON-DATEIEN DETAILANALYSE"
  echo "Pfad | Größe | Keys | Nested Levels | Gültig"
  echo "──────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.json" | while read -r jsonfile; do
    size=$(stat -c%s "$jsonfile" 2>/dev/null || echo "0")
    
    if jq empty "$jsonfile" 2>/dev/null; then
      keys=$(jq 'keys | length' "$jsonfile" 2>/dev/null || echo "0")
      depth=$(jq 'def depth: if type == "object" then 1 + ((.[] | depth) | max // 0) else 0 end; depth' "$jsonfile" 2>/dev/null || echo "0")
      valid="✓"
    else
      keys="ERROR"
      depth="ERROR"
      valid="✗"
    fi
    
    rel_path="${jsonfile#$KI_BASE/}"
    printf '%s | %s | %s | %s | %s\n' "$rel_path" "$size" "$keys" "$depth" "$valid"
  done
} > "$REPORT_DIR/KI_Studio_JSON_Analysis_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 7. MARKDOWN-DOKUMENTATION
# ════════════════════════════════════════════════════════════════════

echo "📝 Markdown-Dateien werden catalogisiert..."

{
  echo "MARKDOWN-DOKUMENTATION"
  echo "Pfad | Zeilen | Überschriften | Links | Code-Blöcke"
  echo "──────────────────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*.md" | while read -r mdfile; do
    lines=$(wc -l < "$mdfile" 2>/dev/null || echo "0")
    headers=$(grep -c '^#' "$mdfile" 2>/dev/null || echo "0")
    links=$(grep -c '\[.*\](.*)\|\](.*)' "$mdfile" 2>/dev/null || echo "0")
    codeblocks=$(grep -c '^```' "$mdfile" 2>/dev/null || echo "0")
    
    rel_path="${mdfile#$KI_BASE/}"
    printf '%s | %s | %s | %s | %s\n' "$rel_path" "$lines" "$headers" "$links" "$codeblocks"
  done
} > "$REPORT_DIR/KI_Studio_Markdown_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 8. VERZEICHNIS-ZWECK-MAPPING
# ════════════════════════════════════════════════════════════════════

echo "🗺️ Zweck-Mapping wird erstellt..."

{
  echo "VERZEICHNIS-ZWECK-MAPPING"
  echo ""
  echo "Verzeichnis | Zweck | Status | Dateien | Größe"
  echo "───────────────────────────────────────────────────────────"
  
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
      [[ -f "$dir/.ready" ]] && status="✓ Ready"
      [[ -f "$dir/.wip" ]] && status="⚠️ WIP"
      [[ ! "$files" -gt 0 ]] && status="📭 Empty"
      
      printf '%s | %s | %s | %d | %s\n' "$dirname" "$purpose" "$status" "$files" "$size"
    fi
  done
} > "$REPORT_DIR/KI_Studio_Purpose_Map_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 9. DEPENDENCIES & IMPORTS (Bash-ORCs)
# ════════════════════════════════════════════════════════════════════

echo "🔗 Abhängigkeiten werden analysiert..."

{
  echo "ORC-DEPENDENCIES (source, . und exec)"
  echo "Script | Abhängigkeiten"
  echo "──────────────────────────────────────"
  
  find "$KI_BASE" -type f -name "*ORC*.sh" -o -name "*orc*.sh" | while read -r orc; do
    deps=$(grep -E 'source|^\.|exec' "$orc" 2>/dev/null | grep -oE '[^ /]+\.(sh|bash)' | sort -u | tr '\n' ' ')
    basename=$(basename "$orc")
    [[ -n "$deps" ]] && printf '%s | %s\n' "$basename" "$deps"
  done
} > "$REPORT_DIR/KI_Studio_ORC_Dependencies_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 10. FUTTER-VERZEICHNIS DEEP-SCAN
# ════════════════════════════════════════════════════════════════════

echo "🍜 KI_Studio_Futter wird detailliert gescannt..."

{
  echo "KI_STUDIO_FUTTER DETAILANALYSE"
  echo "Datei | Typ | Größe | Mtime | Relevanz-Hinweise"
  echo "─────────────────────────────────────────────────"
  
  find "$KI_BASE/KI_Studio_Futter" -maxdepth 3 -type f 2>/dev/null | while read -r file; do
    size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    mtime=$(stat -c%y "$file" 2>/dev/null | cut -d' ' -f1)
    ext="${file##*.}"
    basename=$(basename "$file")
    
    # Relevanz-Hinweise
    hints=""
    case "$ext" in
      md|txt)
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        [[ $lines -gt 100 ]] && hints="📄 Langdokumentation"
        ;;
      json)
        [[ -f "$file" ]] && jq empty "$file" 2>/dev/null && hints="✓ Valid JSON"
        ;;
      sh|bash)
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        [[ $lines -gt 50 ]] && hints="⚙️ Komplexes Skript"
        ;;
      html)
        hints="🌐 Gespeichertes HTML"
        ;;
    esac
    
    printf '%s | %s | %s | %s | %s\n' "$basename" "$ext" "$size" "$mtime" "$hints"
  done
} > "$REPORT_DIR/KI_Studio_Futter_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# 11. SYSTEMD-SERVICES
# ════════════════════════════════════════════════════════════════════

echo "🔧 Systemd-Services werden gescannt..."

{
  echo "SYSTEMD-SERVICES"
  echo "Service | Status | Enabled | Typ"
  echo "���─────────────────────────────────"
  
  for service in KI_Studio*.service KI_Studio*.timer; do
    path="$HOME/.config/systemd/user/$service"
    if [[ -f "$path" ]]; then
      enabled=$(systemctl --user is-enabled "$service" 2>&1 || echo "unknown")
      active=$(systemctl --user is-active "$service" 2>&1 || echo "unknown")
      typ="${service##*.}"
      printf '%s | %s | %s | %s\n' "$service" "$active" "$enabled" "$typ"
    fi
  done
} > "$REPORT_DIR/KI_Studio_Services_${TIMESTAMP}.csv"

# ════════════════════════════════════════════════════════════════════
# AUSGABE
# ════════════════════════════════════════════════════════════════════

echo ""
echo "✅ Scans abgeschlossen!"
echo ""
echo "📊 Reports gespeichert in: $REPORT_DIR/"
echo ""
ls -lh "$REPORT_DIR" | tail -15
echo ""
echo "🚀 Zum Teilen mit GitHub Copilot:"
echo ""
echo "cat $REPORT_DIR/KI_Studio_Structure_L3_${TIMESTAMP}.txt"
echo "cat $REPORT_DIR/KI_Studio_Purpose_Map_${TIMESTAMP}.csv"
echo "cat $REPORT_DIR/KI_Studio_ShellScripts_${TIMESTAMP}.csv"
echo ""
