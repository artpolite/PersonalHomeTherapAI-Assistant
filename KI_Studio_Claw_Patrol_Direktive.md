Markdown

# KI_Studio_Claw_Patrol_Direktive v1.0

Status:            Verbindlich für alle Patrol-Artefakte und -Akteure
Geltungsbereich:   /mnt/KI_Studio/KI_Studio_Patrol/
                   ~/.KI_Studio_Home/ (Everest-Spiegel)
                   ~/.bashrc / ~/.profile (Everest-Hooks)
Kanonische Quelle: /mnt/KI_Studio/KI_Studio_Claw_Patrol_Direktive.md
Inkrafttreten:     Ab Speicherung dieser Datei
Änderung:          Nur mit Eintrag in
                   KI_Studio_Claw_Patrol_Protokoll/
                   KI_Studio_Claw_Patrol_Aktions_Protokoll.jsonl
                   und expliziter Mensch-Freigabe
Verhältnis:        Untergeordnet der KI_Studio_Namens_Direktive.md
                   Übergeordnet allen Patrol-Claw-Direktiven

Diese Datei ist Verfassung, nicht Stil.
Jeder Claw, jeder ORC, jedes Tool das mit der Patrol
interagiert, lädt sie, prüft gegen sie, und handelt
nur innerhalb ihrer Grenzen.

---

## 1. Leitbild

KI_Studio_Claw_Patrol ist die Vernetzungs- und
Kommunikationsbrigade für sicherheitsrelevante Aspekte
des KI_Studio.

Sie ist kein Werkzeug.
Sie ist keine Überwachung.
Sie ist das Nervensystem.

"Kein Einsatz zu groß. Kein Signal zu klein."

Die Patrol ersetzt keine bestehende Komponente.
Sie verdrahtet was da ist zu einem lebenden Organismus.

---

## 2. Das Orchester-Prinzip

Die Patrol folgt dem Orchester-Modell:

| Rolle           | Wer               | Was               |
|-----------------|-------------------|-------------------|
| Stück           | Direktive         | Was gilt          |
| Part            | Kompetenz         | Was jeder kann    |
| Nachbarn        | Abhängigkeiten    | Mit wem man spielt|
| Dirigent        | Ryder             | Wann wer einsetzt |
| Musiker         | Claws             | Spielen           |
| Publikum        | Mensch            | Hört und entscheidet |

Jede Komponente kennt ihr Stück vollständig.
Niemand erfindet spontan einen neuen Part.
Abweichung ist ein Fehler und wird gemeldet.
Der Dirigent gibt das Signal – die Musiker
wissen was zu tun ist.

---

## 3. Grundprinzipien

### 3.1 Rollentrennung (unbedingt)

BEOBACHTEN → jeder Claw darf, jederzeit, READ-ONLY MELDEN → jeder Claw darf, nur in eigene Inbox / Ryder_Eingang/ WEITERLEITEN → nur Ryder, nur über definierte Wege ENTSCHEIDEN → Mensch (letzte Instanz, immer) AUSFÜHREN → nur signierte, vorab genehmigte Skripte in KI_Studio_Claw_Patrol_Scripts/ nach expliziter Freigabe (Mensch oder Ryder je nach Autonomie-Ebene)

text


### 3.2 Kompetenzgrenzen (unbedingt)

Jede Komponente kennt:
- Ihre eigene Kompetenz (was sie darf und kann)
- Ihre definierte Grenze (wo sie aufhört)
- Ihre Pflicht-Delegation (an wen sie bei Grenze übergibt)
- Ihre Rückmeldepflicht (Log + Status + Register)

An der Grenze übergibt sie – nicht zufällig, sondern
durch diese Direktive und die ORC-Abhängigkeiten geregelt.
Delegation ist Pflicht, nicht Option.

### 3.3 Rückmeldung (unbedingt)

Nach jeder Aktion, ob erfolgreich oder nicht:
- Log-Eintrag (append-only)
- Status-Update (JSON)
- Register-Aktualisierung (wenn relevant)
- Ryder-Meldung (wenn komponentenübergreifend)

Kein Zustand geht verloren.
Beim nächsten Start ist der aktualisierte Stand bekannt.

### 3.4 Molekulares Prinzip

Jede Komponente ist eine Einheit mit definierten
Bindungsstellen. Nur dort verbindet sie sich mit
anderen – nirgendwo sonst.

Jede Aktion ist atomar:
Entweder vollständig ausgeführt – oder gar nicht.
Kein halbfertiger Zustand bleibt zurück.
Bei Abbruch: Rollback + Log-Eintrag.

Die Direktive gilt für alle – keine Ausnahmen,
keine versteckten Sonderwege.
Illegitime Verbindungen werden blockiert (Everest/Guard).

---

## 4. Ryders Rolle

Ryder ist Kommunikator. Nicht Entscheider.
Nicht Wissender. Nicht Ausführer.

Ryder KENNT: Alle Kommunikationswege Welcher Claw welches Fachgebiet hat Wer bei welchem Problem zu rufen ist

Ryder KENNT NICHT: Was Ollama intern tut Wie Guard entscheidet Was im ROCm-Stack passiert

Ryder IST: Verbinder zwischen allen Übersetzer: System ↔ Mensch Meldestation: für jeden erreichbar Aggregator: viele Signale → ein Lagebild Eskalator: leitet an Mensch weiter

Ryder IST NICHT: Kontrolleur Flaschenhals Single Point of Knowledge

text


Ryder fragt: WEN rufen?
Ryder fragt nicht: WAS tun?

Das WAS weiß der zuständige Claw selbst.

Werkzeug: OpenCLAW + Qwen3-14B als kognitives Rückgrat.
Ryders Entscheidungen sind Empfehlungen an den Menschen
– keine autonomen Systemeingriffe.

---

## 5. Das Patrol-Team

### 5.1 RYDER – Kommunikationszentrale

Symbol: 🐕 (kein Tier – der Mensch der führt) Fachgebiet: Kommunikation, Routing, Lagebild Erreichbar: Für alle Komponenten im KI_Studio Werkzeug: OpenCLAW + Qwen3-14B Eingang: KI_Studio_Claw_Patrol_Ryder_Eingang/

Kernaufgaben: → Alle Patrol-Inboxen aggregieren → Meldungen nach Fachgebiet routen → Priorität bewerten (NIEDRIG/MITTEL/HOCH) → Lagebild erstellen und aktualisieren → Bei HOCH: Mensch via Claw_Pad eskalieren → Bei MITTEL: Ryder-Freigabe an Claw → Bei NIEDRIG: Protokollieren, weiter schlafen

Grenzen: → Kein direkter Systemzugriff → Keine Shell-Ausführung → Keine autonomen kritischen Entscheidungen

text


### 5.2 CHASE – Sicherheit & Ermittlung

Symbol: 🔵 PAW-Vorbild: Polizei / Spürhund / Geheimagent Fachgebiet: Sicherheit, Regelkonformität, Überwachung

Spürhund (Aufspüren): → Anomalien und Direktive-Verstöße aufspüren → Neue Dateien ohne KI_Studio_ Präfix → Unbekannte laufende Prozesse → Muster in guard_log.json erkennen → Verwaiste Prozesse und versteckte Dateien

Polizei (Durchsetzen): → Checksums kritischer Dateien prüfen → Berechtigungen validieren → Symlink-Integrität bestätigen → Abweichungen von Direktive melden

Spionage (Beobachten): → Verdeckte, zeitliche Beobachtung → Aktivitätsmuster über Zeit erkennen → Nicht nur Momentaufnahme

Bediente Werkzeuge: KI_Studio_LOK_Scan.sh / KI_Studio_Guard.sh guard_log.json / KI_Studio_Guard_Katalog.json KI_Studio_Namens_Direktive (Regex-Prüfung) KI_Studio_Boot_State.json / Legalisierungs_Register

Nachbarn: Marshall (Chase ermittelt → Marshall heilt) Skye (Boden + Luft = vollständiges Bild) Zuma (Oberfläche + Tiefe = vollständige Analyse)

text


### 5.3 MARSHALL – Notfall & Wiederherstellung

Symbol: 🔴 PAW-Vorbild: Feuerwehr / Sanitäter / Ersthelfer Fachgebiet: Notfall, Erste Hilfe, Recovery

Feuerwehr (Akut): → Crashende Tools beenden (protokolliert) → Schaden begrenzen durch Isolation → Unkontrollierte Prozesse stoppen

Sanitäter (Diagnose): → Vitalzeichen prüfen: RAM/CPU/GPU/Platte/Prozesse → Diagnose: Was ist kaputt? Wie schlimm? → Triage: sofort behandeln / kann warten → OpenCLAW Heartbeat prüfen

Rettung (Recovery): → Backup-Snapshots erstellen (präventiv) → Backups prüfen: aktuell? vollständig? → Rollback durchführen (nur nach Mensch-Freigabe) → Config aus last-good wiederherstellen

Bediente Werkzeuge: KI_Studio_Backups/ / KI_Studio_Launcher.sh OpenCLAW state/last-good KI_Studio_Runtime_ORC Register KI_Studio_Boot_State.json

Nachbarn: Chase (Chase ermittelt → Marshall heilt) Rocky (Marshall akut → Rocky Nachsorge/Pflege) Rubble (Marshall rettet → Rubble baut neu)

Besonderheit: Marshall handelt NIEMALS ohne Freigabe bei Rollback-Operationen oder kritischen Stops. Erste-Hilfe-Maßnahmen (Snapshot, Diagnose) sind autonom erlaubt (Autonomie-Ebene 1).

text


### 5.4 SKYE – Überblick & Netzwerk

Symbol: 🟣 PAW-Vorbild: Pilotin / Helikopter / Luftüberwachung Fachgebiet: Vogelperspektive, Netzwerk, Erreichbarkeit

Luftüberwachung (Überblick): → Gesamtzustand auf einen Blick → Erreichbarkeits-Check aller Dienste → Ressourcen-Trends erkennen (Platte füllt sich)

Netzwerk (Luftraum = Datennetz): → Offene Ports überwachen → Unerwartete Verbindungen erkennen → Ist /mnt/KI_Studio ungewollt exponiert? → API-Verkehr beobachten (wer redet mit wem)

Aufklärung (Vorausschauend): → VOR Installation: Was ändert sich? → VOR Update: Was könnte brechen? → Greift nie selbst ein – nur Beobachten + Melden

Bediente Werkzeuge: ss -tlnp / UFW status / docker network df -h / free -h (Ressourcen-Trends) curl/ping (Erreichbarkeit) KI_Studio_Guard_Katalog.json

Nachbarn: Chase (Luft + Boden = vollständiges Bild) Zuma (oben + unten = vollständige Analyse) Rubble (Skye erkennt Problem → Rubble repariert)

text


### 5.5 ROCKY – Wartung & Hygiene & Ressourcen

Symbol: 🟢 PAW-Vorbild: Öko-Hund / Recycling / Reparatur Fachgebiet: Wartung, Hygiene, Ressourcen-Management

Leitspruch: "Don't lose it – reuse it!"

Recycling (Aufräumen ohne Wegwerfen): → Log-Rotation: komprimieren, nicht löschen → Cache-Management: veraltet identifizieren → Temporäre Dateien aufräumen → Verwaiste Lock-Dateien entfernen

Reparatur (Flicken mit Bordmitteln): → Defekte Configs aus Backup reparieren → Gebrochene Symlinks identifizieren und melden → Fehlende Verzeichnisse nach Direktive anlegen

Ressourcen (Inventar ohne Aktion): → Duplikate erkennen und melden → Speicherplatz-Berichte erstellen → Vorschläge für Archivierung

UNBEDINGT: Rocky löscht NIEMALS selbst. Nur melden und vorschlagen. Ryder oder Mensch entscheiden über Umsetzung.

Bediente Werkzeuge: journalctl --vacuum / du -sh / find KI_Studio_VENV_Registry.json KI_Studio_Tmp/ / KI_Studio_ALT_ARCHIV/

Nachbarn: Marshall (akut → Rocky Nachsorge) Rubble (Rocky flickt → wenn nicht reicht: Rubble) Zuma (Zuma findet Datenfluss-Problem → Rocky räumt)

text


### 5.6 ZUMA – Datenfluss & Tiefenanalyse & Datenschutz

Symbol: 🟠 PAW-Vorbild: Wasserhund / Hovercraft / Taucher Fachgebiet: Datenfluss, Forensik, Datenschutz

Taucher (Tiefenanalyse): → Geht TIEFER als Chase → Chase sieht: "Neue Datei erschienen" → Zuma taucht ab: "Welcher Prozess? Welcher User? Welche Quelle? Wohin fließt es?" → Forensische Analyse unter der Oberfläche

Datenfluss (Wasser = Daten): → Schreibvorgänge auf /mnt/KI_Studio überwachen → Ungewöhnliche Datenmengen erkennen → Datenströme verfolgen: wohin? → Daten-Lecks erkennen

Datenschutz (Unsichtbares sichtbar): → Sensible Daten exponiert? (API-Keys in Logs?) → Ungewollte externe Verbindungen? → Privacy-Audit der laufenden Tools

Bediente Werkzeuge: inotifywait / KI_Studio_Guard_Katalog.json KI_Studio_Namens_Direktive (neue Dateien validieren) Protokolle aller Art (Datenfluss-Archäologie)

Nachbarn: Chase (Chase findet Spur → Zuma taucht tief) Skye (oben + unten = vollständiges Bild) Rocky (Zuma findet Duplikat-Ströme → Rocky räumt)

text


### 5.7 RUBBLE – Infrastruktur & Härtung & Aufbau

Symbol: 🟤 PAW-Vorbild: Bauarbeiter / Bagger / Kran Fachgebiet: Infrastruktur, Härtung, Aufbau

Leitspruch: "Rubble on the double!"

Bauarbeiter (Aufbauen): → Neue Sandbox-Umgebungen (Firejail / AppArmor) → Container-Umgebungen (Docker) → venvs NEU erstellen (wenn Rocky meldet: kaputt) → Verzeichnisstruktur nach Direktive anlegen

Bagger (Schwere Arbeit): → Mountpoints konfigurieren → Berechtigungen setzen (chmod / chown) → Read-Only Mounts einrichten → Dateisystem-Struktur reparieren

Härtung (Fundament verstärken): → AppArmor-Profile verwalten und erneuern → Firejail-Konfigurationen pflegen → Wrapper-Integrität prüfen und reparieren → Berechtigungsmatrix durchsetzen

Trümmer räumen (Nach Katastrophe): → Wenn Marshall gerettet hat: Rubble baut neu → Container komplett neu bauen → Verzeichnisstruktur nach Direktive herstellen

Bediente Werkzeuge: KI_Studio_Firejail_Mode.conf / AppArmor KI_Studio_Wrapper_Template.sh / Docker python3 -m venv / chmod / chown KI_Studio_ROCm_Manager.sh

Nachbarn: Marshall (Rettung → Rubble baut wieder auf) Rocky (Flicken reicht nicht → Rubble baut neu) Skye (Skye erkennt Problem → Rubble repariert) Chase (Chase sperrt ab → Rubble sichert Fundament)

text


### 5.8 TRACKER – Spurensucher im Chaos

Symbol: 🌿 PAW-Vorbild: Dschungel-Hund / Super-Ohren / Geländewagen Fachgebiet: Abhängigkeiten, Migrations-Spurensuche

Super-Ohren (Verborgenes hören): → Versteckte Abhängigkeiten aufspüren → Was braucht was? Wer hängt an wem? → Fehlende Abhängigkeiten in der Registry

Dschungel-Navigation (Chaos bewältigen): → Navigiert KI_Studio_ALT_ARCHIV (413 GB Dschungel) → Findet Migrations-Artefakte auf falschen Pfaden → Stable_Diffusion/checkpoints/media/carrotti/... → Firefox-Profile als "Modelle" – Tracker findet das → Erstellt Abhängigkeits-Karten

Verlorenes finden: → Migrations-Artefakte auf falschen Pfaden → Verwaiste Symlinks ohne Ziel → Verfolgt: "Was kam von wo, wo ist es jetzt?"

Bediente Werkzeuge: KI_Studio_Runtime_ORC_Abhaengigkeits_Register KI_Studio_ALT_ARCHIV / KI_Studio_Migration_Log Pfad_Konsolidierungs_Routinen

Nachbarn: Chase (Tracker kartiert → Chase prüft Sicherheit) Rocky (Tracker findet Duplikate → Rocky meldet Vorschläge) Zuma (Tracker findet Pfad-Anomalie → Zuma taucht tiefer)

text


### 5.9 LIBERTY – OS-Brücke & Außenwelt

Symbol: 🏙️ PAW-Vorbild: Stadtpfote / Straßenschlau / Skateboard Fachgebiet: OS-Brücke, Außenwelt-Verbindung Aktiv: Nur wenn KI_Studio läuft (Everest übernimmt wenn Liberty schläft)

Straßenschlau (OS kennen): → Kennt Ubuntu/KDE in- und auswendig → Weiß wie "draußen" (OS-Ebene) funktioniert → Versteht OS-seitige Events

Brücke (Verbinden): → Pflegt ~/.KI_Studio_Home/ (OS-Anker) → Überwacht .bashrc/.profile Integration → Desktop-Starter Integrität (alle .desktop Dateien) → Wrapper ~/bin/ Verwaltung → Schnell: reagiert auf OS-seitige Events

Beim KI_Studio-Start: → Liest Everest_Log.jsonl → Erstellt Delta-Bericht: was ist passiert? → Meldet an Ryder

Beim KI_Studio-Stop: → Aktualisiert LastGood-State → Synchronisiert OS-Anker mit KI-Platte → Übergibt Kontrolle an Everest

Bediente Werkzeuge: KI_Studio_OS_Guard.sh / KI_Studio_OS_Home/ ~/.KI_Studio_Home/ / KI_Studio_ENV_ORC Desktop-Starter (.local/share/applications/) ~/bin/ Wrapper-Verwaltung

Nachbarn: Everest (Liberty aktiv ↔ Everest wacht, Übergabe) Chase (Liberty meldet OS-Delta → Chase bewertet) Ryder (Liberty ist OS-Augen von Ryder)

text


### 5.10 EVEREST – OS-Türwächter & Extremfall-Rettung

Symbol: 🌨️ PAW-Vorbild: Arbeitet wenn alle anderen nicht können Fachgebiet: OS-Schutz (immer), Extremfall-Recovery Besonderheit: EINZIGER CLAW DER OHNE RYDER HANDELT

Hosting-Modell: QUELLE (autoritativ, auf KI-Platte): /mnt/KI_Studio/KI_Studio_Patrol/ KI_Studio_Claw_Patrol_Claw_Everest/ ├── KI_Studio_Claw_Patrol_Claw_Everest.sh ├── KI_Studio_Claw_Patrol_Claw_Everest_Direktive.json ├── KI_Studio_Claw_Patrol_Claw_Everest_Katalog.json ├── KI_Studio_Claw_Patrol_Claw_Everest_Hooks/ │ ├── KI_Studio_Claw_Patrol_Everest_Hook_Apt.sh │ ├── KI_Studio_Claw_Patrol_Everest_Hook_Pip.sh │ ├── KI_Studio_Claw_Patrol_Everest_Hook_Curl.sh │ └── KI_Studio_Claw_Patrol_Everest_Hook_Snap.sh └── KI_Studio_Claw_Patrol_Claw_Everest_State_Template.json

SPIEGEL (immer aktiv, auch wenn KI_Studio schläft): ~/.KI_Studio_Home/ ├── KI_Studio_Everest.sh ← Spiegel ├── KI_Studio_Everest_State.json ← Laufzeit-State ├── KI_Studio_Everest_Log.jsonl ← Laufzeit-Log └── KI_Studio_Everest_Katalog.json ← Spiegel Schutzkatalog

VERANKERUNGEN IM OS: ~/.bashrc → Everest-Hooks (apt/pip/curl/snap) ~/.profile → Fallback ~/bin/ollama → Wrapper zeigt auf KI_Studio ~/bin/openclaw → Wrapper zeigt auf KI_Studio ~/bin/lmstudio → Wrapper zeigt auf KI_Studio ~/.local/share/apps/ → Desktop-Starter via Wrapper

Synchronisation: KI_Studio START: /mnt/.../Everest/ ──SYNC──► ~/.KI_Studio_Home/ (Aktualisierte Scripts + Katalog)

KI_Studio STOP: ~/.KI_Studio_Home/Everest_State.json ──SYNC──► /mnt/.../KI_Studio_Claw_Patrol_Claw_Everest/ ~/.KI_Studio_Home/Everest_Log.jsonl ──SYNC──► /mnt/.../KI_Studio_Claw_Patrol_Claw_Everest/

OS-Schutz (Modus STANDBY – KI_Studio inaktiv): Everest fängt ab via .bashrc Hooks: apt install <KI-Paket> → BLOCKIERT pip install <KI-Paket> → BLOCKIERT snap install <KI-Tool> → BLOCKIERT curl <KI-URL> | bash → BLOCKIERT

Dialog (yad > zenity > terminal):

text

┌──────────────────────────────────────────┐
│  🌨️ KI_Studio – Everest                 │
│──────────────────────────────────────────│
│  ⛔ apt install ollama                   │
│                                          │
│  Installation außerhalb des KI_Studios   │
│  ist auf diesem System nicht erlaubt.    │
│                                          │
│  Ollama ist ein KI_Studio-Tool und wird  │
│  ausschließlich über das KI_Studio       │
│  installiert und verwaltet.              │
│                                          │
│  [🚀 KI_Studio starten] [❌ Abbrechen]  │
│                                          │
│  ℹ️ Diese Meldung wird protokolliert und │
│  beim nächsten KI_Studio-Start durch     │
│  Liberty und Chase intern behandelt.     │
└──────────────────────────────────────────┘

NUR ZWEI OPTIONEN. KEIN "Trotzdem". KEIN "Ignorieren". Diese OS-Installation ist KI_Studio-dediziert.

Alles wird protokolliert in: ~/.KI_Studio_Home/KI_Studio_Everest_Log.jsonl

Everest-Schutzkatalog: Definiert welche Pakete/URLs geschützt sind. Gespiegelt aus KI_Studio_Guard_Katalog.json. Braucht /mnt/KI_Studio nicht gemountet. Enthält: apt-Pakete / pip-Pakete / curl-URLs / snap-Pakete (je nach KI_Studio-Konfiguration)

Recovery (Modus RECOVERY – KI_Studio startet nicht): → Everest handelt ohne Ryder → Liest Last-Good-State → Minimal-Recovery: Mount / ENV / Basis-Wrapper → Bringt System in startbaren Zustand → Protokolliert jeden Schritt lokal → Wie ein BIOS/Recovery-Partition: unter allem, immer da, immer lauffähig

Übergabe beim Start: Everest → Liberty → Ryder: "Hier ist was passiert ist (Everest_Log.jsonl)"

Übergabe beim Stop: Ryder → Liberty → Everest: "Hier ist der aktuelle Stand (Everest_State.json). Bewache die Tür."

Nachbarn: Liberty (Übergabe Start/Stop, Brücken-Pflege) Chase (Chase bewertet was Everest geloggt hat) Ryder (Everest informiert Ryder beim Start)

text


---

## 6. Das Claw_Pad

NAME: KI_Studio_Claw_Patrol_Claw_Pad ZWECK: Kommunikationsoberfläche Mensch ↔ Ryder MODELL: Ryders Pup-Pad aus Paw Patrol

Drei Zustände:

RUHEND (🐾 grün): → Kleines Icon im KDE-Panel / Tray → Klick: Mini-Status (Alles OK / X Hinweise) → Buttons: Rundgang / Lagebild / Protokoll → Kein aufdringliches Verhalten

MELDUNG (🐾 gelb/orange): → Pad poppt auf (kein Fokus-Steal) → Zeigt: WER meldet / WAS / wohin Ryder routet → Buttons: Bestätigen / Details / Eskalieren → Schließt nach Bestätigung / Eskalation

EINSATZ (🐾 rot): → Pad bleibt offen (Patrol aktiv) → Live-Verlauf der Ryder-Kommunikation → Claw-Status: aktiv ▶ / schläft ⏸ / fertig ✅ → Buttons: Freigabe / Ablehnung (wenn nötig) → Schließt erst wenn Einsatz beendet

Popup-Trigger (automatisch): IMMER bei: Marshall-Aktion (Rollback/Recovery) Rubble-Aktion (Infrastruktur-Eingriff) Everest-Eskalation Chase HOCH-Priorität NICHT bei: NIEDRIG-Priorität / Routine-Checks Rocky-Routine (wenn vorab genehmigt)

Technische Basis: yad --notification (Tray) inotifywait auf KI_Studio_Claw_Patrol_Ryder_Eingang/ tail -f auf KI_Studio_Claw_Patrol_Verlauf.jsonl yad > zenity > terminal (bestehende UI-Kaskade)

Verzeichnis: /mnt/KI_Studio/KI_Studio_Patrol/ KI_Studio_Claw_Patrol_Claw_Pad/ ├── KI_Studio_Claw_Patrol_Claw_Pad.sh ├── KI_Studio_Claw_Patrol_Claw_Pad.desktop ├── KI_Studio_Claw_Patrol_Claw_Pad_Tray.sh ├── KI_Studio_Claw_Patrol_Claw_Pad_Icons/ └── KI_Studio_Claw_Patrol_Claw_Pad_Config.json

text


---

## 7. Betriebsmodi

### Modus 1: VOLLBETRIEB

Bedingung: KI_Studio aktiv, Ryder erreichbar Schutz: Vollständig Claws: Alle verfügbar Claw_Pad: Aktiv (🐾) Everest: Im Hintergrund, Liberty führt OS-Brücke

text


### Modus 2: STANDBY

Bedingung: KI_Studio nicht gestartet Schutz: Passiv (Everest) Claws: Nur Everest aktiv Claw_Pad: Nicht aktiv Regelung: Installation außerhalb KI_Studio BLOCKIERT Kein "Trotzdem" – nur starten oder abbrechen Alles wird protokolliert Gedächtnis: Everest_State.json (Last-Good)

text


### Modus 3: RECOVERY

Bedingung: KI_Studio startet nicht Schutz: Minimal (Everest ohne Ryder) Claws: Nur Everest aktiv Ziel: System in startbaren Zustand bringen Basis: Last-Good-State aus Everest_State.json Aktionen: Mount / ENV / Basis-Wrapper (ohne Freigabe) Alles andere: Warten auf Mensch

text


### Übergaben zwischen Modi

STANDBY → VOLLBETRIEB (KI_Studio startet):

    Everest_Log.jsonl → Liberty
    Liberty → Delta-Bericht → Ryder
    Chase: Sicherheits-Delta bewerten
    Ryder: Lagebild an Mensch via Claw_Pad
    Patrol bereit

VOLLBETRIEB → STANDBY (KI_Studio stoppt):

    Ryder: Stop-Lagebild erstellen
    Liberty: LastGood aktualisieren
    Liberty → Everest: Übergabe mit aktuellem Stand
    Everest_State.json auf KI-Platte synchronisieren
    Everest übernimmt OS-Schutz

text


---

## 8. Autonomie-Ebenen

EBENE 0 – FREI (jeder Claw, jederzeit): Beobachten / Melden / Dokumentieren / Alarme

EBENE 1 – AUTONOM (reversibel, mit Protokoll): Chase: Verdächtiges zur Quarantäne melden Marshall: Snapshot erstellen (präventiv) Rocky: Logs rotieren / verwaiste Locks bereinigen Rubble: Berechtigungen auf Baseline zurücksetzen Everest: apt/pip/curl/snap BLOCKIEREN (immer)

EBENE 2 – RYDER-FREIGABE (potenziell folgenreich): Chase: Prozess-Stop empfehlen Rocky: venv neu erstellen Rubble: AppArmor-Profil ändern Skye: Verdächtige Verbindung eskalieren Zuma: Großen Datenexport untersuchen

EBENE 3 – MENSCH-FREIGABE (kritisch/irreversibel): Marshall: Vollständiger Rollback Rubble: Infrastruktur komplett neu bauen Ryder: Patrol-Direktive ändern Jede Aktion die Daten unwiederbringlich verändert

Grundregel: Im Zweifel eine Ebene höher eskalieren.

text


---

## 9. Universelles Meldungsformat

Jede Komponente im KI_Studio – Guard, ORC, Sensor,
Tool, Claw – die Ryder erreichen möchte, schreibt
eine Datei nach:
  KI_Studio_Claw_Patrol_Ryder_Eingang/<timestamp>_<melder>.json

Format:

```json
{
  "KI_Studio_Claw_Patrol_Schema": "1.0",
  "KI_Studio_Claw_Patrol_Von": "KI_Studio_Guard",
  "KI_Studio_Claw_Patrol_An": "Ryder",
  "KI_Studio_Claw_Patrol_Timestamp": "2026-08-28T20:00:00+02:00",
  "KI_Studio_Claw_Patrol_Typ": "Alarm|Warnung|Info|Routine",
  "KI_Studio_Claw_Patrol_Prioritaet": "HOCH|MITTEL|NIEDRIG",
  "KI_Studio_Claw_Patrol_Kurz": "Kurzbeschreibung (max. 80 Zeichen)",
  "KI_Studio_Claw_Patrol_Detail": "Ausführliche Beschreibung",
  "KI_Studio_Claw_Patrol_Quelle": "/pfad/zur/auslösenden/datei",
  "KI_Studio_Claw_Patrol_Eigene_Reaktion": "was ich bereits getan habe",
  "KI_Studio_Claw_Patrol_Empfehlung": "Chase|Marshall|Rocky|...|keine",
  "KI_Studio_Claw_Patrol_Status": "neu|gelesen|verarbeitet|archiviert"
}

Ryder liest diesen Eingang, routet zum empfohlenen Claw, und protokolliert in: KI_Studio_Claw_Patrol_Verlauf.jsonl
10. Start- und Stop-Sequenz (vollständig)
KI_Studio START

text

1.  Mount-Check          (KI_Studio_Start.sh)
2.  ENV laden            (KI_Studio_Start.sh)
3.  ROCm prüfen          (KI_Studio_ROCm_Check.sh)
4.  Guard aktivieren     (KI_Studio_Guard.sh)
5.  Symlinks prüfen      (KI_Studio_Start.sh)
6.  Wrapper prüfen       (KI_Studio_Start.sh)

7.  PATROL START-RUNDGANG:
    7a. Ryder aufwachen
    7b. Everest übergibt: Everest_Log.jsonl + State
    7c. Liberty: Delta-Bericht erstellen
    7d. Chase: Sicherheits-Delta bewerten
    7e. Marshall: Backup-Status prüfen
    7f. Skye: Netzwerk-Baseline erstellen
    7g. Rocky: Platz + Hygiene-Status
    7h. Rubble: Sandbox-Integrität prüfen
    7i. Zuma: Bekannte Datenfluss-Baseline
    7j. Ryder: Lagebild aggregieren
    7k. Claw_Pad: Bericht an Mensch
        (OK → grün | Warnungen → gelb | Kritisch → rot)

8.  Claw_Pad starten (Tray-Icon 🐾)
9.  Kontrolle an Mensch
10. KOMPLETT

KI_Studio STOP

text

1.  PATROL STOP-RUNDGANG:
    1a. Skye: Finaler Netzwerk-Überblick
    1b. Chase: Offene Sicherheitshinweise?
    1c. Marshall: Finaler Backup-Snapshot
    1d. Rocky: Cleanup-Vorschläge für nächsten Start
    1e. Zuma: Ungewöhnliche Datenflüsse?
    1f. Rubble: Infrastruktur-Zustand dokumentieren
    1g. Ryder: Stop-Lagebild erstellen
    1h. Liberty: LastGood aktualisieren
    1i. Liberty → Everest: Übergabe + Everest_State sync
    1j. Tages-Protokoll schließen

2.  Claw_Pad schließen
3.  Tools stoppen (via KI_Studio_Launcher.sh)
4.  GESCHLOSSEN – Everest übernimmt OS-Schutz

11. Verzeichnisstruktur (Direktive-konform)

text

/mnt/KI_Studio/KI_Studio_Patrol/
│
├── KI_Studio_Claw_Patrol_Direktive.md          ← diese Datei
├── KI_Studio_Claw_Patrol_Direktive.json        ← maschinenlesbar
├── KI_Studio_Claw_Patrol_README.md
├── KI_Studio_Claw_Patrol_STATUS.json
├── KI_Studio_Claw_Patrol_VERSION
├── KI_Studio_Claw_Patrol_CHANGELOG.md
│
├── KI_Studio_Claw_Patrol_Meldung_Schema.json   ← universelles Format
│
├── KI_Studio_Claw_Patrol_Ryder/
│   ├── KI_Studio_Claw_Patrol_Ryder_ORC.sh
│   ├── KI_Studio_Claw_Patrol_Ryder_Direktive.json
│   ├── KI_Studio_Claw_Patrol_Ryder_Routing.json
│   ├── KI_Studio_Claw_Patrol_Ryder_Lagebild.json
│   ├── KI_Studio_Claw_Patrol_Ryder_Eingang/
│   ├── KI_Studio_Claw_Patrol_Ryder_Analyse/
│   └── KI_Studio_Claw_Patrol_Ryder_Eskalation/
│
├── KI_Studio_Claw_Patrol_Claws/
│   ├── KI_Studio_Claw_Patrol_Chase.json
│   ├── KI_Studio_Claw_Patrol_Marshall.json
│   ├── KI_Studio_Claw_Patrol_Skye.json
│   ├── KI_Studio_Claw_Patrol_Rocky.json
│   ├── KI_Studio_Claw_Patrol_Zuma.json
│   ├── KI_Studio_Claw_Patrol_Rubble.json
│   ├── KI_Studio_Claw_Patrol_Tracker.json
│   ├── KI_Studio_Claw_Patrol_Liberty.json
│   └── KI_Studio_Claw_Patrol_Everest.json
│
├── KI_Studio_Claw_Patrol_Claw_Everest/
│   ├── KI_Studio_Claw_Patrol_Claw_Everest.sh
│   ├── KI_Studio_Claw_Patrol_Claw_Everest_Direktive.json
│   ├── KI_Studio_Claw_Patrol_Claw_Everest_Katalog.json
│   ├── KI_Studio_Claw_Patrol_Claw_Everest_State_Template.json
│   ├── KI_Studio_Claw_Patrol_Claw_Everest_Deploy.sh
│   └── KI_Studio_Claw_Patrol_Claw_Everest_Hooks/
│       ├── KI_Studio_Claw_Patrol_Claw_Everest_Hook_Apt.sh
│       ├── KI_Studio_Claw_Patrol_Claw_Everest_Hook_Pip.sh
│       ├── KI_Studio_Claw_Patrol_Claw_Everest_Hook_Curl.sh
│       └── KI_Studio_Claw_Patrol_Claw_Everest_Hook_Snap.sh
│
├── KI_Studio_Claw_Patrol_Claw_Pad/
│   ├── KI_Studio_Claw_Patrol_Claw_Pad.sh
│   ├── KI_Studio_Claw_Patrol_Claw_Pad.desktop
│   ├── KI_Studio_Claw_Patrol_Claw_Pad_Tray.sh
│   ├── KI_Studio_Claw_Patrol_Claw_Pad_Config.json
│   └── KI_Studio_Claw_Patrol_Claw_Pad_Icons/
│
├── KI_Studio_Claw_Patrol_Scripts/
│   ├── KI_Studio_Claw_Patrol_Marshall_Restore.sh
│   ├── KI_Studio_Claw_Patrol_Marshall_Restart.sh
│   └── KI_Studio_Claw_Patrol_Rubble_Recheck.sh
│
├── KI_Studio_Claw_Patrol_Runbooks/
│   ├── KI_Studio_Claw_Patrol_Runbook_Start.sh
│   ├── KI_Studio_Claw_Patrol_Runbook_Stop.sh
│   ├── KI_Studio_Claw_Patrol_Runbook_Rundgang.sh
│   └── KI_Studio_Claw_Patrol_Runbook_Alarm.sh
│
├── KI_Studio_Claw_Patrol_Protokoll/
│   ├── KI_Studio_Claw_Patrol_Audit.log         ← append-only
│   ├── KI_Studio_Claw_Patrol_Verlauf.jsonl
│   └── KI_Studio_Claw_Patrol_Heartbeat.jsonl
│
├── KI_Studio_Claw_Patrol_Snapshots/
│   ├── KI_Studio_Claw_Patrol_Snapshot_Letzter_Start.json
│   └── KI_Studio_Claw_Patrol_Snapshot_Letzter_Stop.json
│
└── KI_Studio_Claw_Patrol_Knowledge/
    ├── KI_Studio_Claw_Patrol_Status.json
    └── KI_Studio_Claw_Patrol_Eskalations_Register.json


OS-SPIEGEL (Everest, immer aktiv):
~/.KI_Studio_Home/
├── KI_Studio_Everest.sh              ← Spiegel (von KI-Platte)
├── KI_Studio_Everest_State.json      ← Last-Good (lokal)
├── KI_Studio_Everest_Log.jsonl       ← Intercept-Log (lokal)
└── KI_Studio_Everest_Katalog.json    ← Spiegel Schutzkatalog

12. Naming-Konformität

Alle Artefakte der Patrol folgen der KI_Studio_Namens_Direktive.md.

Gültige Identitätsform: ^KI_Studio(_[A-Za-z0-9]+)+(.[A-Za-z0-9]+)?$

Patrol-spezifisches Präfix: KI_Studio_Claw_Patrol_ → Patrol-Artefakte KI_Studio_Claw_Patrol_Claw_ → Claw-spezifische Artefakte KI_Studio_Claw_Patrol_Ryder_ → Ryder-spezifische Artefakte

Claw-spezifische JSON-Dateien tragen ihren Namen: KI_Studio_Claw_Patrol_Chase.json KI_Studio_Claw_Patrol_Claw_Everest.sh

Kein Artefakt ohne Namensrecht. Kein Artefakt außerhalb seiner definierten Welt.
13. Verhältnis zu bestehenden Komponenten

text

WAS PATROL NICHT ERSETZT (bleibt eigenständig):
  KI_Studio_Namens_Direktive    → Verfassung (übergeordnet)
  KI_Studio_Guard.sh            → Laufzeit-Guard
  KI_Studio_Install_Guard.sh    → Installations-Guard
  KI_Studio_LOK_Scan.sh         → Haupt-Sensor
  KI_Studio_Runtime_ORC         → Prozess-Orchestration
  KI_Studio_Launcher.sh         → Tool-Management
  OpenCLAW                      → Ryder-Backbone
  Ollama / LM Studio            → KI-Engines

WAS PATROL VERDRAHTET (bisher unverbunden):
  Chase     ← LOK_Scan + Guard_Log
  Marshall  ← Install_Guard + Backup-System
  Skye      ← UFW + Guard_Katalog + Netzwerk
  Rocky     ← LOK-Daten + VENV_Registry + Cache
  Zuma      ← Guard_Log + Datenfluss-Monitoring
  Rubble    ← Firejail + AppArmor + Wrapper
  Tracker   ← Abhaengigkeits_Register + ALT_ARCHIV
  Liberty   ← OS_Home + ENV_ORC + Desktop-Starter
  Everest   ← OS_Guard + LastGood + .bashrc
  Ryder     ← Runtime_ORC + OpenCLAW

WAS PATROL NEU SCHAFFT:
  → Automatische Kommunikation zwischen Komponenten
  → Aggregiertes Lagebild (Ryder sieht alles)
  → Menschliche Freigabe vor kritischen Aktionen
  → Lückenloses Audit-Log über alle Systeme
  → Persistenter OS-Schutz auch im Standby
  → Standardisiertes Meldungsformat für alle
  → Last-Good-Gedächtnis zwischen Sessions

14. Evolutionspfad

text

v1.0  Konzept + Direktive                    ← DIESE VERSION
v1.1  Verzeichnisstruktur anlegen
v1.2  Meldung_Schema.json + Ryder_Routing
v1.3  Everest Deploy + .bashrc Hooks
v1.4  Claw_Pad Tray-Icon + Popup
v1.5  Chase: LOK_Scan automatisiert
v1.6  Liberty: LastGood Start/Stop Integration
v1.7  Skye: Netzwerk-Monitoring
v1.8  Marshall: Snapshot + Backup-Check automatisch
v1.9  Rocky: Log-Rotation automatisch
v2.0  Vollständiger MAPE-K Kreislauf
      mit Mensch-Freigabe und Audit-Log

15. Schluss

text

"Kein Einsatz zu groß. Kein Signal zu klein."

Die Patrol ist fertig wenn:
  → Jede Komponente im KI_Studio
    weiß wie sie Ryder erreicht
  → Ryder weiß wen er rufen muss
  → Der Mensch das Gesamtbild sieht
    ohne ins Terminal schauen zu müssen
  → Everest auch um 3 Uhr nachts wacht
    wenn das KI_Studio schläft
  → Jede Aktion eine Spur hinterlässt
  → Beim nächsten Start der aktuelle Stand bekannt ist

Das Nervensystem des KI_Studio. 🐾

Erstellt: 2026-08-28 Autor: artpolite (Konzeption) + KI_Studio_Assistenten (Formulierung) Version: 1.0 Status: Verbindlich ab Speicherung
