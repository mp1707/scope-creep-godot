# Scope Creep PoC

Godot-Zielversion: 4.6.

## Starten

Das Projekt startet ueber `res://scenes/application/Main.tscn`. Im Editor kann die Szene mit Play gestartet werden.

Der Vertical Slice startet mit Software, Entwickler, Idee, Kaffee, Booster-Slot und drei 1-Geld-Karten. Der Dev-Overlay zeigt Sprint, Phase, Timer sowie Speichern/Laden und Bezahlaktionen. Er ist in `MainApplication.show_dev_overlay` abschaltbar.

## Spielen

- Idee auf Entwickler ziehen, um eine Funktion zu bauen.
- Funktion auf Software ziehen, um Geld zu erzeugen. Dabei kann ein Bug entstehen.
- Geld auf Entwickler ziehen, um ihn in der Bezahlphase zu bezahlen.
- In der Bezahlphase `Sprint N starten` klicken, um Sprintstart-Effekte auszufuehren.
- Geld auf Booster-Slot ziehen, dann Geld auf Boosterpack ziehen, um drei Karten zu ziehen.
- Leertaste pausiert nur waehrend der Sprint-Phase.
- Speichern ist nur in Pause oder Bezahlphase erlaubt.

## Checks

Alle PoC-Kernchecks laufen ueber:

```bash
tools/check_poc.sh
```

Falls Godot nicht am Standardpfad liegt:

```bash
GODOT_BIN=/pfad/zu/Godot tools/check_poc.sh
```
