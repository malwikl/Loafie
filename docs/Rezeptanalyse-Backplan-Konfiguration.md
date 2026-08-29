# Rezeptanalyse und automatische Backplan-Konfiguration

## Zusammenfassung

Loafie erhält eine Rezeptimport-Funktion für:

- Rezept-URL
- eingefügten Rezepttext

Die Analyse läuft auf unterstützten Geräten vollständig lokal mit Apple Foundation Models. Die Funktion wird ab iOS 26 angeboten; der bestehende Backplan-Timer bleibt ab iOS 18 verfügbar.

Das Ergebnis wird nicht direkt gespeichert. Stattdessen zeigt Loafie eine editierbare Prüfansicht mit erkannten Zutaten, Prozessschritten, Zeiten, Bedingungen und Unsicherheiten. Erst nach Bestätigung wird daraus ein `BakePlan`.

## Erkenntnisse aus den Rezepten

Die Rezepte unterscheiden sich stark:

- [BBC Good Food](https://www.bbcgoodfood.com/recipes/homemade-sourdough-bread) verwendet feste Zeiten für Autolyse, Bulk-Fermentation und Raumtemperatur- oder Kühlschrankgare.
- [The Perfect Loaf](https://www.theperfectloaf.com/best-sourdough-recipe/) kombiniert konkrete Uhrzeiten, Levain-Aufbau, Autolyse, sechs Faltserien mit unterschiedlichen Intervallen, vier Stunden Bulk-Fermentation und eine Übernachtgare.
- [King Arthur Baking](https://www.kingarthurbaking.com/recipes/high-hydration-whole-wheat-sourdough-bread-recipe) beschreibt mehrtägige Abläufe mit Starter, Preferment, Autolyse, Bowl-/Coil-/Lamination-Folds und einem variablen Kühlschrankfenster.
- [University of Illinois Extension](https://extension.illinois.edu/sites/default/files/2024-11/sourdough_bread_recipes_handout_final.pdf) empfiehlt bei der Bulk-Fermentation teilweise Temperatur und prozentualen Volumenzuwachs statt einer festen Zeit.

Daraus folgt: Die Analyse muss feste Zeiten, Zeitfenster, relative Abhängigkeiten und manuelle Zustandsbedingungen getrennt behandeln.

## Implementierungsänderungen

### 1. Rezeptimport

Neue Services:

- `RecipeSourceLoader`
  - lädt URLs mit `URLSession`,
  - extrahiert den Haupttext aus HTML,
  - entfernt Navigation, Werbung und irrelevante Seitenelemente,
  - fordert bei blockierten oder unlesbaren Seiten zum Einfügen des Rezepttexts auf.
- `RecipeTextNormalizer`
  - vereinheitlicht Zeilenumbrüche, Einheiten und Listen,
  - erkennt Rezeptabschnitte wie Zutaten, Levain, Autolyse, Methode und Backen,
  - begrenzt oder segmentiert lange Texte für das Foundation-Models-Kontextfenster.
- Unterstützte Sprachen der ersten Version: Deutsch und Englisch.

Die Original-URL und der vom Nutzer analysierte Text werden für Nachvollziehbarkeit gespeichert.

### 2. Strukturierte On-Device-Analyse

Die Analyse erhält eine typisierte Ausgabe mit `@Generable`, nicht freiem JSON.

Vorgesehene Analyse-Strukturen:

- `RecipeAnalysisDraft`
  - Rezeptname
  - erkannte Ausbeute beziehungsweise Laibanzahl
  - Zutatenabschnitte
  - Prozessschritte
  - erkannte Zeitangaben und Zeitfenster
  - Temperaturangaben
  - Bedingungen
  - Unsicherheiten und Konfidenz
- `RecipeIngredientDraft`
  - Name
  - Menge
  - Einheit
  - Gruppe, zum Beispiel Starter, Levain oder Hauptteig
- `RecipeProcessStepDraft`
  - Titel
  - erkannter Schritt-Typ
  - Dauer oder Zeitfenster
  - Temperatur
  - relative Beziehung zu vorherigen Schritten
  - manuelle Bedingung
  - relevante Originalpassage

Die Foundation-Models-Nutzung folgt diesen Regeln:

- Verfügbarkeit über `SystemLanguageModel.default.availability` prüfen.
- Analyse nur auf iOS 26+ und Apple-Intelligence-fähigen Geräten anbieten.
- Analyse in asynchronen Tasks ausführen.
- Lange Rezepte in sinnvolle Abschnitte aufteilen.
- Kontextüberläufe, nicht unterstützte Sprachen und Analysefehler sichtbar behandeln.
- Die Modellantwort darf keine fehlenden Zeiten oder Bedingungen erfinden.

### 3. Zuordnung zu Loafie-Backplänen

Die erkannten Prozessschritte werden folgendermaßen abgebildet:

| Rezeptschritt | Loafie-Zuordnung |
|---|---|
| Starter-/Levain-Aufbau | Benutzerdefinierter Schritt |
| Autolyse | `.autolyse` |
| Mischen | `.mix` |
| Kneten oder Falten beim Mischen | `.kneading` oder benutzerdefinierter Schritt |
| Bulk-Fermentation | `.bulkRoomTemperature` oder `.bulkCold` |
| Stretch-and-Fold-/Coil-Fold-Serien | Faltungs-Erinnerungen oder Untertimer |
| Vorformen | `.benchRest` beziehungsweise benutzerdefinierter Schritt |
| Formen | `.shaping` |
| Raumtemperaturgare | `.finalProofRoomTemperature` |
| Kühlschrankgare | `.coldFinalProof` oder `.bulkCold` |
| Backen | `.bake` |
| Abkühlen | `.cooling` |
| Nicht eindeutig zuordenbare Schritte | Benutzerdefinierter Schritt mit Originaltitel und Notiz |

Starter- und Levain-Vorstufen werden als eigene Schritte übernommen.

Explizite Zeitangaben werden als relative Schritt- oder Erinnerungszeiten gespeichert. Angaben wie „am nächsten Morgen“ oder konkrete Uhrzeiten werden nicht an ein festes Datum gebunden, sondern in relative Abhängigkeiten und einen Start-/Zielanker übersetzt.

Bedingungen wie „bis verdoppelt“, „bis 50 % Volumenzuwachs“, „bis der Teig bereit ist“ oder „bei 25 °C“ werden als manuelle Prüfpunkte mit Notizen gespeichert. Eine erkannte Dauer oder Zeitspanne darf nur als Orientierung verwendet werden und wird in der Prüfansicht als Schätzung gekennzeichnet.

### 4. Persistenz

Neues SwiftData-Modell `Recipe`:

- Titel
- Original-URL
- Originaltext
- erkannte Sprache
- Analysezeitpunkt
- Analyseversion
- Analyse-Status
- gespeicherte Analyse beziehungsweise normalisierte Metadaten

Neues SwiftData-Modell `RecipeIngredient`:

- Name
- Menge
- Einheit
- Zutatenabschnitt
- optionale Bäckerprozente

`BakePlan` erhält eine optionale Beziehung zu `Recipe`.

Die Datenmodelle werden in allen `ModelContainer`-Definitionen, Previews und Tests ergänzt. Die Erweiterung darf bestehende Backpläne und laufende Sessions nicht verändern.

### 5. Prüfansicht

Neue Ansicht „Rezept analysieren“:

1. URL oder Rezepttext eingeben.
2. Quelle laden und bereinigen.
3. Analyse starten.
4. Zutaten und erkannte Prozessschritte anzeigen.
5. Unsichere Werte und Schätzungen hervorheben.
6. Titel, Typ, Dauer, Reihenfolge, Bedingungen und Notizen korrigieren.
7. Einzelne Schritte ausschließen.
8. „Backplan erstellen“ bestätigen.
9. Einen normalen, vollständig editierbaren `BakePlan` erzeugen.

Die Prüfansicht zeigt immer, welche Angaben direkt aus dem Rezept stammen und welche abgeleitet oder geschätzt wurden.

Bei fehlender Foundation-Models-Unterstützung wird die Funktion nicht angezeigt. Die übrige Backplan- und Timerfunktion bleibt nutzbar.

## Tests und Abnahmekriterien

- URL mit sauber strukturiertem Rezept wird korrekt geladen.
- Rezepttext kann direkt eingefügt und analysiert werden.
- HTML-Navigation und Werbung werden nicht als Prozessschritte übernommen.
- Deutsche und englische Rezepte werden unterstützt.
- Zutaten mit Gramm, Millilitern, Prozenten und Einheiten werden normalisiert.
- Starter, Levain und Preferment werden als eigene Abschnitte erkannt.
- Autolyse, Mischen, Bulk-Fermentation, Falten, Formen, Kaltgare und Backen werden korrekt zugeordnet.
- Faltserien mit unterschiedlichen Abständen werden korrekt als Erinnerungen modelliert.
- Kühlschrank-Zeitfenster werden als Minimum, Ziel und Maximum übernommen, sofern vorhanden.
- Bedingungen ohne feste Zeit werden als manuelle Prüfpunkte gespeichert.
- Absolute Tagesangaben werden nicht fälschlich an ein vergangenes Datum gebunden.
- Unsichere oder widersprüchliche Werte erscheinen in der Prüfansicht.
- Ein Backplan wird erst nach Nutzerbestätigung gespeichert.
- Änderungen an der Analyse beeinflussen nur den neu erzeugten Backplan.
- Quelle, Originaltext und Zutaten bleiben nach App-Neustart verfügbar.
- Analysefehler, zu lange Texte und nicht unterstützte Sprachen werden verständlich angezeigt.
- Das Feature bleibt auf iOS 18 deaktiviert, ohne bestehende Funktionen zu beeinträchtigen.
- Foundation-Models-Aufrufe werden über ein Protokoll abstrahiert und mit deterministischen Testantworten getestet.
- Bestehende Timer-, Planungs-, SwiftData- und Session-Tests bleiben erfolgreich.

## Annahmen

- Die erste Version verwendet keine Cloud-KI.
- URL-Inhalte werden online geladen, die semantische Analyse bleibt lokal.
- Die Analyse unterstützt zunächst Deutsch und Englisch.
- Es werden keine fehlenden Prozesszeiten erfunden.
- Zutaten werden gespeichert, aber nicht automatisch skaliert.
- Der Nutzer bleibt für die fachliche Prüfung und endgültige Backplan-Konfiguration verantwortlich.
- Die Funktion wird in den bestehenden „Backpläne“-Bereich integriert und erhält keinen zusätzlichen Haupttab.
