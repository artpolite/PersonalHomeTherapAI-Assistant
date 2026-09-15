#!/usr/bin/env bash
# KI_Studio_Shallow_Audit.sh
# Oberflächlicher, gezielter Audit der KI_Studio-Struktur
# 
# PRINZIPIEN:
#   - Max 3 Ebenen tief
#   - Nur KI_Studio-eigene Artefakte detailliert (.sh, .json, .md, .jsonl)
#   - Fremdsoftware strukturell erfasst (Verzeichnis ja/nein)
#   - Kompakt (<1MB), copy-paste-ready
#   - Terminal-only, keine Dialoge
#   - Fokus: Direktive-Konformität

set -u
umask 077

# ════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ════════════════════════════════════════════════════════════════════

KI_BASE="/mnt/KI_Studio"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

# ════════════════════════════════════════════════════════════════════
# VALIDIERUNG
# ════════════════════════════════════════════════════════════════════

if [[ ! -d "$KI_BASE" ]]; then
    echo "❌ FEHLER: $KI_BASE nicht vorhanden oder nicht gemountet"
    exit 1
fi

# ════════════════════════════════════════════════════════════════════
# HEADER
# ════════════════════════════════════════════════════════════════════

cat <<'HEADER'
╔════════════════════════════════════════════════════════════════════════╗
║                  KI_Studio Shallow Audit                              ║
║                                                                        ║
║  Gezielter, oberflächlicher Audit der KI_Studio-Struktur              ║
║  • Max 3 Ebenen tief                                                   ║
║  • KI_Studio-eigene Artefakte detailliert                              ║
║  • Fremdsoftware strukturell                                           ║
║  • Direktive-Konformität im Fokus                                      ║
╚════════════════════════════════════════════════════════════════════════╝

HEADER

echo "🔍 Scan startet: $(date '+%F %T %Z')"
echo ""

# ════════════════════════════════════════════════════════════════════
# 1. TOP-LEVEL STRUKTUR
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  TOP-LEVEL STRUKTUR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

{
  printf '%s | %s | %s\n' "Verzeichnis" "Typ" "Status"
  printf '%s\n' "──────────────────────────────────────────────────────"
  
  for item in "$KI_BASE"/*; do
    if [[ -d "$item" ]]; then
      name=$(basename "$item")
      
      # Klassifizierung
      if [[ "$name" =~ ^KI_Studio_ ]]; then
        typ="KI_Studio-Welt"
      else
        typ="Fremdsoftware"
      fi
      
      # Status (leer/vorhanden)
      files=$(find "$item" -maxdepth 1 -type f 2>/dev/null | wc -l)
      subdirs=$(find "$item" -maxdepth 1 -type d 2>/dev/null | wc -l)
      total=$((files + subdirs - 1))
      
      if [[ $total -eq 0 ]]; then
        status="📭 Leer"
      else
        status="✓ OK ($total Einträge)"
      fi
      
      printf '%s | %s | %s\n' "$name" "$typ" "$status"
    fi
  done
}
echo ""

# ════════════════════════════════════════════════════════════════════
# 2. KI_STUDIO-EIGENE WELTEN (DETAILLIERT BIS EBENE 3)
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  KI_STUDIO-WELTEN: Kritische ORCs und Direktiven"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Nur KI_Studio_ Welten
for world in "$KI_BASE"/KI_Studio_*; do
  if [[ ! -d "$world" ]]; then
    continue
  fi
  
  worldname=$(basename "$world")
  echo "📂 $worldname"
  echo "   ─────────────────────────────────────────"
  
  # Suche nach KI_Studio-Dateien (max 2 Ebenen tief)
  find "$world" -maxdepth 2 -type f \
    \( -name "KI_Studio_*.sh" -o -name "KI_Studio_*.json" \
    -o -name "KI_Studio_*.md" -o -name "KI_Studio_*.jsonl" \
    -o -name "*Direktive*" -o -name "*ORC*" -o -name "*Guard*" \) \
    2>/dev/null | while read -r file; do
    
    rel_path="${file#$world/}"
    size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    exec_flag=$(test -x "$file" && echo "✓" || echo "✗")
    
    # Kurze Beschreibung
    filename=$(basename "$file")
    case "$filename" in
      *ORC*) desc="[ORC]" ;;
      *Guard*) desc="[Guard]" ;;
      *Direktive*) desc="[Direktive]" ;;
      *Protokoll*) desc="[Protokoll]" ;;
      *) desc="[Datei]" ;;
    esac
    
    printf '   %s %s %s (%s bytes)\n' "$exec_flag" "$desc" "$rel_path" "$size"
  done
  
  echo ""
done

# ════════════════════════════════════════════════════════════════════
# 3. PROGRAMMEBENE (KI_Studio/)
# ════════════════════════════════════════════��═══════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  PROGRAMMEBENE: /mnt/KI_Studio/KI_Studio/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROG_BASE="$KI_BASE/KI_Studio"

if [[ -d "$PROG_BASE" ]]; then
  echo "Workload-Welten:"
  printf '%s | %s | %s\n' "Welt" "Status" "KI_Studio-Dateien"
  printf '%s\n' "──────────────────────────────────────────────────"
  
  for world in "$PROG_BASE"/*; do
    if [[ -d "$world" ]]; then
      wname=$(basename "$world")
      
      # Status
      files=$(find "$world" -maxdepth 1 -type f 2>/dev/null | wc -l)
      [[ $files -eq 0 ]] && status="📭" || status="✓"
      
      # KI_Studio-Dateien zählen
      ki_files=$(find "$world" -maxdepth 2 -type f -name "KI_Studio_*" 2>/dev/null | wc -l)
      
      printf '%s | %s | %d\n' "$wname" "$status" "$ki_files"
    fi
  done
  echo ""
else
  echo "⚠️  Programmebene nicht vorhanden"
  echo ""
fi

# ════════════════════════════════════════════════════════════════════
# 4. FREMDSOFTWARE (STRUKTURELL)
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  FREMDSOFTWARE: Erkannte Tools und Container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Bekannte Fremdsoftware-Identifier
declare -A FOREIGN=(
  ["ollama"]="Ollama (LLM Server)"
  ["lmstudio"]="LM Studio (GUI LLM)"
  ["comfyui"]="ComfyUI (Stable Diffusion)"
  ["fooocus"]="Fooocus (ComfyUI Fork)"
  ["StableDiffusion"]="Stable Diffusion"
  ["stable-diffusion-webui"]="SD WebUI"
  ["vosk"]="Vosk (Speech Recognition)"
  ["piper"]="Piper (TTS)"
  ["mycroft"]="Mycroft (Voice Assistant)"
  ["rhasspy"]="Rhasspy (Wake Word)"
  ["Joplin"]="Joplin (Notes)"
  ["Pinokio"]="Pinokio (AI App Manager)"
  ["StabilityMatrix"]="Stability Matrix (SD Manager)"
  ["deep-speech"]="DeepSpeech (Speech-to-Text)"
  ["local-ai"]="LocalAI (LLM)"
  ["open-assistant"]="Open Assistant"
  ["docker_data"]="Docker Volumes"
)

echo "Erkannte fremde Tools:"
printf '%s | %s | %s\n' "Tool" "Pfad" "Status"
printf '%s\n' "──────────────────────────────────────────────────────"

for tool_dir in "$KI_BASE"/*; do
  if [[ ! -d "$tool_dir" ]]; then
    continue
  fi
  
  tool_name=$(basename "$tool_dir")
  
  # Nicht in KI_Studio_-Welten suchen (die haben wir oben)
  if [[ "$tool_name" =~ ^KI_Studio_ ]]; then
    continue
  fi
  
  # Mit bekannten Tools abgleichen
  for key in "${!FOREIGN[@]}"; do
    if [[ "$tool_name" =~ $key ]] || [[ "$key" =~ $tool_name ]]; then
      desc="${FOREIGN[$key]}"
      
      # Status
      files=$(find "$tool_dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
      [[ $files -eq 0 ]] && status="📭" || status="✓"
      
      printf '%s | %s | %s\n' "$desc" "$tool_name/" "$status"
      break
    fi
  done
done

echo ""

# ════════════════════════════════════════════════════════════════════
# 5. KRITISCHE DATEIEN - KONFORMITÄTSPRÜFUNG
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  KRITISCHE DATEIEN: Direktive-Konformität"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -a CRITICAL=(
  "$KI_BASE/KI_Studio_Namens_Direktive.md"
  "$KI_BASE/KI_Studio_Claw_Patrol_Direktive.md"
  "$KI_BASE/KI_Studio_SYS/KI_Studio_SYS_Direktive.md"
  "$KI_BASE/KI_Studio_OS_Home/KI_Studio_OS_Home_Direktive.md"
  "$HOME/.KI_Studio_Home/KI_Studio_Everest.sh"
  "$HOME/.KI_Studio_Home/KI_Studio_Everest_State.json"
)

printf '%s | %s\n' "Datei" "Status"
printf '%s\n' "──────────────────────────────────────────────────────────"

for file in "${CRITICAL[@]}"; do
  if [[ -f "$file" ]]; then
    printf '✓ | %s\n' "$file"
  else
    printf '✗ | %s\n' "$file"
  fi
done

echo ""

# ════════════════════════════════════════════════════════════════════
# 6. START-KETTE
# ══════════════════════════════════════════════════════════════���═════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  START-KETTE: Launcher und ORCs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -a START_CHAIN=(
  "$KI_BASE/KI_Studio_Start.sh"
  "$KI_BASE/KI_Studio_SYS_ORC.sh"
  "$KI_BASE/KI_Studio_Launcher.sh"
  "$HOME/.KI_Studio_Home/KI_Studio_Start.sh"
)

printf '%s | %s | %s\n' "Script" "Exec" "Status"
printf '%s\n' "────────────────────────────────────────────────────"

for script in "${START_CHAIN[@]}"; do
  if [[ -f "$script" ]]; then
    exec_flag=$(test -x "$script" && echo "✓" || echo "✗")
    size=$(stat -c%s "$script" 2>/dev/null || echo "?")
    printf '%s | %s | %d bytes\n' "$(basename $script)" "$exec_flag" "$size"
  else
    printf '%s | %s | %s\n' "$(basename $script)" "✗" "FEHLT"
  fi
done

echo ""

# ════════════════════════════════════════════════════════════════════
# 7. HOME-BRIDGE
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  HOME-BRIDGE: ~/.KI_Studio_Home/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HOME_BRIDGE="$HOME/.KI_Studio_Home"

if [[ -d "$HOME_BRIDGE" ]]; then
  printf '%s | %s\n' "Datei" "Status"
  printf '%s\n' "────────────────────────────────────────────"
  
  find "$HOME_BRIDGE" -maxdepth 1 -type f 2>/dev/null | sort | while read -r file; do
    fname=$(basename "$file")
    printf '✓ | %s\n' "$fname"
  done
  echo ""
else
  echo "⚠️  $HOME_BRIDGE nicht vorhanden"
  echo ""
fi

# ════════════════════════════════════════════════════════════════════
# 8. KI_STUDIO_FUTTER - TOP-LEVEL NUR
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  KI_STUDIO_FUTTER: Top-Level Inhaltstypen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FUTTER="$KI_BASE/KI_Studio_Futter"

if [[ -d "$FUTTER" ]]; then
  printf '%s | %s | %s\n' "Datei" "Typ" "Größe"
  printf '%s\n' "────────────────────────────────────────────────────"
  
  find "$FUTTER" -maxdepth 1 -type f 2>/dev/null | sort | while read -r file; do
    fname=$(basename "$file")
    ext="${fname##*.}"
    size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    size_h=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "${size}B")
    
    printf '%s | %s | %s\n' "$fname" "$ext" "$size_h"
  done
  
  echo ""
  echo "Top-Level Verzeichnisse:"
  find "$FUTTER" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | sort | while read -r dir; do
    dname=$(basename "$dir")
    files=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
    printf '  📂 %s (%d Dateien)\n' "$dname" "$files"
  done
  
  echo ""
else
  echo "⚠️  $FUTTER nicht vorhanden"
  echo ""
fi

# ════════════════════════════════════════════════════════════════════
# ABSCHLUSS
# ════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ AUDIT ABGESCHLOSSEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Scan beendet: $(date '+%F %T %Z')"
echo ""
echo "💡 Tipps:"
echo "   • Terminal speichern oder kopieren"
echo "   • Vergleich mit KI_Studio_Namens_Direktive.md"
echo "   • Gaps/Fehler notieren für nächste Iteration"
echo ""
