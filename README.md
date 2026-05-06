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
- Geld auf Booster-Slot ziehen, dann Boosterpack dreimal anklicken, um die Karten einzeln zu ziehen.
- Leertaste pausiert nur waehrend der Sprint-Phase.
- Speichern ist nur in Pause oder Bezahlphase erlaubt.

## PoC2-Playtest

PoC2 ist ohne Debug-Spawns spielbar. Product Owner, Tester, Externer Dev, Kunde, Kaffeemaschine, Auftraege, Office-Consumables und Bugfix-Patch kommen ueber die Shop-Slots am Board ins Spiel.

Empfohlene Testlaeufe:

1. Schnellschuss: Idee + Entwickler direkt zu Funktion bauen, ungeprueft releasen, Bugs/Tech Debt nur behandeln, wenn sie stoeren.
2. Saubere Pipeline: Talent-Pool kaufen, Product Owner und Tester nutzen, User Story -> Funktion -> Gepruefte Funktion -> Software spielen.
3. Eskalation: Bugs bewusst liegen lassen, bis Sprintstart aus drei Bugs einen Prod-Crash bildet.
4. Office-Invest: Office-Invest kaufen, Kaffeemaschine/Kaffee und Burnout-Heilung mit Pizza Party oder Stressbewaeltigungskurs testen.
5. Kundenchaos: Kunde/Auftrag/Kundenwunsch nutzen und pruefen, ob genug Druck fuer die laengere Pipeline entsteht.

## Checks

Alle PoC-Kernchecks laufen ueber:

```bash
tools/check_poc.sh
```

Falls Godot nicht am Standardpfad liegt:

```bash
GODOT_BIN=/pfad/zu/Godot tools/check_poc.sh
```
