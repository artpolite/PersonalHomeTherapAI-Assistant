# KI_Studio_OS_Home

## Zweck
`KI_Studio_OS_Home` ist die kanonische, dauerhafte und portable OS-Brücke des KI_Studios.

## Grundsatz
- `/mnt/KI_Studio/KI_Studio_OS_Home/` = führende Quelle
- `/home/artpolite/.KI_Studio_Home/` = minimaler aktiver Host-Anker / Spiegel
- Das Betriebssystem hostet nur die minimal nötigen KI_Studio-Anker
- Die eigentliche Ordnung, Protokollierung und Referenz liegt auf der KI_Studio-Platte

## Namensdirektive
Alle Verzeichnisse, Dateien und Skripte in diesem Bereich tragen ihren Bereich und ihre Funktion transparent im Namen:

- `KI_Studio_OS_ORC.sh`
- `KI_Studio_OS_install.sh`
- `KI_Studio_OS_Profiles/`
- `KI_Studio_OS_Logs/`
- `KI_Studio_OS_State/`
- `KI_Studio_OS_Protokoll/`
- `KI_Studio_OS_Backups/`
- `KI_Studio_OS_Vorlagen/`
- `KI_Studio_OS_Legacy/`

## Rollen
### KI_Studio_OS_ORC.sh
Dachrolle für:
- `status`
- `pruefen`
- `profiles`
- `install`
- `logs`
- `hilfe`
- `version`

### KI_Studio_OS_install.sh
Operative OS-Basisaktionsroutine:
- Profile lesen
- Pakete prüfen
- nur fehlende Pakete installieren
- SYSTEM-Aktionen bestätigen
- `yad > zenity > terminal` als Dialogkaskade
- Status und Protokoll fortschreiben

## Erste Profile
- `KI_Studio_OS_Profile_Basis.manifest`
- `KI_Studio_OS_Profile_Dialog.manifest`
- `KI_Studio_OS_Profile_Python.manifest`
- `KI_Studio_OS_Profile_Docker.manifest`
- `KI_Studio_OS_Profile_Vulkan.manifest`

## Legacy
Das ursprüngliche Vorläufermaterial bleibt im Futter und wird hier nicht überschrieben.
