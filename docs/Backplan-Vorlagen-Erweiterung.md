# Erweiterung: Eigene Backplan-Vorlagen und wiederverwendbare Schritte

## Zusammenfassung

Die bestehenden drei Backplan-Vorlagen bleiben unverändert als Startvorlagen erhalten. Nutzer können künftig:

- einen leeren Backplan oder eine vorhandene Vorlage beziehungsweise einen bestehenden Plan kopieren,
- vorhandene Schritte übernehmen,
- neue benutzerdefinierte Schritte anlegen,
- Schritte per Drag & Drop umsortieren, aktivieren, deaktivieren und löschen,
- eigene Schritte als wiederverwendbare Bausteine speichern.

Ein eingefügter Baustein wird immer als unabhängige Kopie in den Backplan übernommen. Spätere Änderungen am Baustein verändern keine bestehenden Pläne.

## Implementierungsänderungen

### Datenmodell

- Neues SwiftData-Modell `StepTemplate` für wiederverwendbare benutzerdefinierte Schritte.
- Speicherung von Name, Schrittart, Dauer, Mindest-/Maximaldauer, Temperatur, Notizen, Faltungs-Konfiguration und Erinnerungen, sofern zutreffend.
- Neues zugehöriges SwiftData-Modell für die Erinnerungen eines Schrittbausteins.
- Alle neuen Modelle in den `ModelContainer`-Definitionen, Previews und Tests registrieren.
- Bestehende `BakePlan`- und `BakeSession`-Daten bleiben erhalten.
- Beim Einfügen werden neue IDs erzeugt und alle Beziehungen korrekt neu aufgebaut.

### Plan-Erstellung und Verwaltung

- Der Plus-Button öffnet eine Auswahl:
  - Leerer Backplan
  - Same-Day-Vorlage
  - Overnight-/Cold-Proof-Vorlage
  - Cold-Bulk-Vorlage
  - Kopie eines bestehenden Backplans
- Ein leer gestarteter Plan darf den Editor erst verlassen, wenn mindestens ein Schritt vorhanden ist.
- Bestehende Pläne bleiben bearbeitbar, duplizierbar und löschbar.
- Eine laufende Session bleibt beim späteren Bearbeiten oder Löschen des Plans unverändert, da sie bereits als Snapshot gespeichert ist.

### Schritt-Editor

- Im Bereich „Schritte“:
  - „Schritt hinzufügen“
  - vorhandene Schrittarten
  - gespeicherte benutzerdefinierte Bausteine
  - Löschen
  - Umsortieren per `onMove`
- Nach jeder Änderung wird `sortIndex` für alle Schritte neu nummeriert.
- Ein neuer benutzerdefinierter Schritt bietet eigenen Namen, Dauer, Notizen und Erinnerungen.
- Benutzerdefinierte Schritte dürfen vorhandene Erinnerungsarten verwenden.
- Spezialfelder wie Kälte-Zeitfenster und Faltungs-Erinnerungen bleiben an die dafür geeigneten Schrittarten gebunden.
- Aus jedem bearbeiteten Schritt kann „Als Baustein speichern“ gewählt werden.
- Ein eigener Bereich „Bausteine verwalten“ ist direkt aus „Schritt hinzufügen“ erreichbar:
  - Baustein umbenennen
  - Baustein bearbeiten
  - Baustein löschen
- Das Bearbeiten oder Löschen eines Bausteins beeinflusst bereits eingefügte Kopien nicht.

### Timing-Auswahl

- Die bestehende Auswahl „Same day“, „Overnight“ und „Cold bulk“ bleibt im Editor sichtbar.
- Das Anwenden einer anderen Vorlage ersetzt alle aktuellen Schritte erst nach einer Bestätigung.
- Die Warnung weist darauf hin, dass manuelle Änderungen, eigene Schritte und die aktuelle Reihenfolge ersetzt werden.
- Das bestehende Timing-Modell bleibt erhalten; ein zusätzlicher `custom`-Timing-Modus ist nicht erforderlich.

## Tests und Abnahmekriterien

- Leerer Plan kann erstellt und mit Schritten gefüllt werden.
- Speichern ohne Schritte wird verhindert.
- Plan kann aus jeder bestehenden Startvorlage erstellt werden.
- Bestehender Plan kann vollständig dupliziert werden.
- Schritte können hinzugefügt, gelöscht, aktiviert/deaktiviert und umsortiert werden.
- `sortIndex` bleibt nach jeder Reihenfolgeänderung eindeutig und lückenlos.
- Benutzerdefinierte Schritte werden mit Name, Dauer, Notizen und Erinnerungen korrekt gespeichert.
- Ein Schrittbaustein kann gespeichert und in mehrere Pläne eingefügt werden.
- Änderungen am Baustein verändern keine bereits eingefügten Kopien.
- Baustein-Erinnerungen werden beim Kopieren mit neuen IDs und korrekten Beziehungen übernommen.
- Vorlage anwenden zeigt eine Bestätigung und ersetzt danach die Schritte korrekt.
- Bestehende laufende Sessions bleiben von Planänderungen unabhängig.
- SwiftData-Speicherung und Wiederherstellung nach App-Neustart werden getestet.
- Bestehende Timer-, Planungs- und Session-Tests bleiben erfolgreich.

## Annahmen

- „Backplan“ ist der vom Nutzer gespeicherte Plan; die eingebauten Standardpfade bleiben Startvorlagen.
- Benutzerdefinierte Bausteine werden lokal mit SwiftData gespeichert.
- Es gibt weiterhin höchstens eine laufende oder geplante Session gleichzeitig.
- Die Erweiterung benötigt keinen Cloud-Sync und kein Benutzerkonto.
- Die bestehenden englischen String-Keys und deutschen Übersetzungen werden für alle neuen UI-Texte ergänzt.
