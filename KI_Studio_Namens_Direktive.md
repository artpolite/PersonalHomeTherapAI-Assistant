# KI_Studio_Namens_Direktive v1.1

**Status:** Verbindlich für alle neuen KI_Studio-eigenen Artefakte

**Geltungsbereich:**
- `/mnt/KI_Studio/` (KI-Platte)
- `~/.KI_Studio_Home/` (OS-Bridge/Spiegel, minimal)
- `~/bin/` (nur Wrapper/Aliasse)
- `~/.local/share/applications/` (nur `KI_Studio_*.desktop`)

**Kanonische Quelle:**
```
/mnt/KI_Studio/KI_Studio_Namens_Direktive.md
```

**Ziel:**
- Eindeutige, parsbare, governance-konforme Benennung aller KI_Studio-eigenen Verzeichnisse/Dateien/States/Skripte
- Fremdsoftware im KI_Studio darf NICHT umbenannt werden (Updatefähigkeit)

> Diese Datei ist **Verfassung**, nicht Stil.
> Bei Verstoß (bei NEU) wird nichts Neues angelegt (kein stilles Umbenennen).

---

## 0) Kanonische Pfade (Ebenenmodell)

### KI_Studio Root (Governance + wenige Welten)
```
KI_STUDIO_ROOT=/mnt/KI_Studio
```

### KI_Studio Programmebene (Workloads/Anwendersoftware)
```
KI_STUDIO_PROGRAM_ROOT=/mnt/KI_Studio/KI_Studio
```

### Home-Bridge (OS-Ebene, minimal)
```
KI_STUDIO_HOME_NS=~/.KI_Studio_Home
```

### Docker (Variante 1, verbindlich)
```
Docker data-root liegt ausserhalb von KI_STUDIO_PROGRAM_ROOT
(z.B. /mnt/KI_Studio/KI_Studio_Docker/...)
```

---

## 1) Grundprinzipien

- **KI_Studio-eigene Identität trägt immer das Präfix:** `KI_Studio_`
- **Kanonische Identität trennt nur mit `_` (Unterstrich)**
- **Keine Leerzeichen, keine Umlaute, kein ß, keine Sonderzeichen** in KI_Studio-Identitäten
- **Platte ist Wahrheit, Home ist Türklinke/Spiegel**
- **Altbestand wird nicht heimlich umbenannt** (Migration ist bewusst und bestätigt)
- **Fremdsoftware wird nicht umbenannt**

---

## 2) Grammatik (nur für KI_Studio-eigene Identität)

### Muster
```
KI_Studio_<WELT>[<QUALIFIER>...][<ROLLE>][.ext]
```

### Gültigkeitsregel (Regex)
```
^KI_Studio(_[A-Za-z0-9]+)+(.[A-Za-z0-9]+)?$
```

### Gültig
- `KI_Studio_SYS_Guard.sh`
- `KI_Studio_Runtime_Sitzung_State.json`
- `KI_Studio_OS_Aktions_Protokoll.jsonl`
- `KI_Studio_Namens_Direktive.md`

### Ungültig als KI_Studio-Identität
- `logs/` `config/` `state/`
- `install.sh` `status.json`
- `KI-Studio_foo` `ki_studio_bar`

---

## 3) Weltenregister (Top-Level Tokens unter `/mnt/KI_Studio`)

> Neue Top-Level-Welten sind **Architektur** (nicht Schreiblaune).
> Neue Welt erfordert: Direktive + Guard + zuständigen ORC.

### Erlaubte Welten (Top-Level Identitäten)

```
KI_Studio_SYS
KI_Studio_SYS_ORC
KI_Studio_Runtime
KI_Studio_Runtime_ORC
KI_Studio_OS_Home
KI_Studio_ROCm
KI_Studio_LOK
KI_Studio_AGENDA
KI_Studio_Config
KI_Studio_Logs
KI_Studio_Backups
KI_Studio_Import
KI_Studio_ALT / KI_Studio_ALT_ARCHIV
KI_Studio_Futter
KI_Studio_Docker
KI_Studio_Namens (diese Verfassung)
```

### Hinweis
Die Programmebene ist **keine Welt**, sondern ein Containerpfad:
```
/mnt/KI_Studio/KI_Studio/
```

---

## 4) Programmebene (Workloads) – Strukturregeln

Unter `KI_STUDIO_PROGRAM_ROOT=/mnt/KI_Studio/KI_Studio` liegen Workload-Welten:

```
KI_Studio_Tools/
KI_Studio_Models/
KI_Studio_Data/
KI_Studio_Cache/
KI_Studio_Plugins/
KI_Studio_Workspaces/
```

### Regel
- Neue Workload-Artefakte dürfen **nicht mehr auf Root-Ebene erzeugt werden** (z.B. `/mnt/KI_Studio/KI_Studio_Tools`), wenn Programmebene aktiv ist
- Altbestand bleibt Bestand und wird einzeln migriert

---

## 5) Fremdsoftware im KI_Studio (Containment ohne Umbenennung)

Innerhalb eines konformen KI_Studio-Roots (z.B. `.../KI_Studio_Tools/<tool_id>/`) darf Fremdinnenleben bleiben.

### Erlaubt als Fremdinnenleben (Beispiele, nicht abschließend)
- `README.md`, `LICENSE`, `COPYING`, `NOTICE`
- `.git/`, `node_modules/`, `venv/`, `.venv/`, `pycache/`
- `package.json`, `pyproject.toml`, `requirements.txt`, `.env.example`
- Drittdateien/Modelnamen mit `-` oder anderen Zeichen

### Wichtig
- Diese Fremd-Dateien sind **NICHT Quelle der KI_Studio-Wahrheit**
- KI_Studio-eigene Wahrheit/States/Policies müssen `KI_Studio_`-konform benannt sein

### Empfohlen (Transparenz pro Tool)
- `KI_Studio_Tools_<ToolID>_README.md` (KI_Studio-Doku zusätzlich)
- `KI_Studio_Tools_<ToolID>_Status_ref.md` (nur Referenz/Schema, nicht steuernd)

---

## 6) Extensions und Bedeutung (KI_Studio-eigene Dateien)

| Extension | Bedeutung |
|-----------|-----------|
| `.sh` | ORC, Guard, Wrapper, Installer, Launcher |
| `.json` | State/Config/Register/Status (maschinenlesbar, keine Kommentare) |
| `.jsonl` | Protokoll/Audit (eine Aktion pro Zeile) |
| `.yaml` | Profile/Vorlagen |
| `.md` | Dokumentation / Referenz (`_ref.md` nur lesend) |
| `.log` | Rohe Ausgabe (nicht als Wahrheit) |
| `.desktop` | `KI_Studio_*.desktop` |

### Neu verboten als KI_Studio-Wahrheit
```
state.json / status.json / policy.json / config.json
ohne KI_Studio_-Präfix
```

---

## 7) Rollenmodell (ORC/Guard/Installer/Launcher)

### Namensmuster (KI_Studio-eigene Artefakte)
```
KI_Studio_<WELT>_ORC.sh
KI_Studio_<WELT>_Guard.sh
KI_Studio_<WELT>_Install.sh oder KI_Studio_<WELT>_Setup.sh
KI_Studio_<WELT>_Launcher.sh
KI_Studio_Start.sh / KI_Studio_Stop.sh
```

### Sicherheitsregel
> Kein `.sh` darf `sudo`/`apt`/`dpkg`/`systemctl` ohne SYSTEM-Freigabe + Benutzerdialog ausführen.

---

## 8) Statusarten (niemals mischen)

```
Soll:      KI_Studio_<WELT>_Soll_Status.json
Ist:       KI_Studio_<WELT>_Ist_Status.json
Sitzung:   KI_Studio_<WELT>_Sitzung_State.json
Spiegel:   KI_Studio_Home_<WELT>_Spiegel_State.json
Protokoll: KI_Studio_<WELT>_Aktions_Protokoll.jsonl
```

### Regel
- **Spiegel überschreibt nie die zentrale Quelle**
- Bei Widerspruch: neu prüfen

---

## 9) Alias vs Identität (Türklinke-Regel)

### Alias (darf kurz sein)
```
~/bin/ollama, ~/bin/openclaw, ~/bin/lmstudio, ~/bin/KI_Studio
~/.local/share/applications/KI_Studio_*.desktop
```

### Alias darf nicht
- Eigene Datenwelten im Home aufbauen
- Quelle der Wahrheit sein
- Ohne Mount-Check arbeiten

---

## 10) Home gegen Platte (Bridge-Policy)

### Platte: `/mnt/KI_Studio/...`
- **Ist Identität und Wahrheit**

### Home: `~/.KI_Studio_Home/`
- **Ist Anker und Spiegel**

### Erlaubt im Home
- Wrapper (`~/bin/*`)
- Desktop-Dateien (`KI_Studio_*.desktop`)
- Spiegel/State/Guard-Konfig, wenn explizit als Spiegel/Bridge markiert

### Nicht erlaubt als neue Wahrheit im Home
- Tooldaten/Modelle
- Neue herrenlose `config/`, `state/`, `logs/` als Identität
- Unpräfixierte KI_Studio-Wahrheitsdateien

---

## 11) Ableitung MD ↔ JSON (Hash-Regel)

Diese MD ist **kanonisch**.

`KI_Studio_Direktive.json` wird 1:1 abgeleitet und enthält mindestens:

```json
{
  "source_md_path": "/mnt/KI_Studio/KI_Studio_Namens_Direktive.md",
  "source_md_sha256": "...",
  "json_sha256": "...",
  "generated_at": "..."
}
```

> **Bei Hash-Mismatch:** Guard meldet Drift und blockiert neue Writes bis geklärt.

---

## Ende der KI_Studio_Namens_Direktive v1.1

**Kanonische Quelle:** `/mnt/KI_Studio/KI_Studio_Namens_Direktive.md`
