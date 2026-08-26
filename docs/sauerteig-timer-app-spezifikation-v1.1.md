# Spezifikation: Sauerteig-Timer (V1.2)

> Aktualisiert am 24.08.2026. Dieses Dokument beschreibt sowohl das Produktziel als auch den gegenwärtigen Implementierungsstand der App. Abschnitte mit dem Status **Implementiert**, **Teilweise implementiert** oder **Offen** sind die verbindliche Grundlage für die weitere Produktarbeit.

## Zielbild

Eine fokussierte iPhone-App zur Planung und Durchführung eines einzelnen Sauerteig-Backvorgangs. Die App unterstützt keine Rezepte im engeren Sinn, sondern bildet ausschließlich Zeitpläne, Phasen und Erinnerungen ab.

Der Schwerpunkt liegt auf einem ruhigen, sehr klaren UI: Der Nutzer soll jederzeit erkennen, **was jetzt zu tun ist**, **wie lange die aktuelle Phase noch läuft** und **was als Nächstes ansteht**. Eine begleitende Apple-Watch-App zeigt den laufenden Status, erinnert an fällige Schritte und bietet begrenzte Schnellaktionen.

## Geltungsbereich

### In V1 enthalten

- iPhone-App, vollständig lokal nutzbar
- Ein aktiver Backvorgang gleichzeitig
- Eigene Zeitpläne erstellen, bearbeiten, duplizieren, speichern und löschen
- Same-Day- und Overnight-Abläufe
- Kühlschrankphasen als Cold Bulk oder Cold Final Proof
- Einzel-, Intervall- und Phasen-Timer
- Lokale Benachrichtigungen
- Pausieren, Fortsetzen, Abschließen und Verlängern einer laufenden Phase
- Rückwärtsplanung aus einer gewünschten Backzeit
- Übersicht über den gesamten Ablauf als Timeline
- Begleitende Apple-Watch-App zur Anzeige, Erinnerung und Ausführung definierter Schnellaktionen

### Explizit nicht in V1

- Kein Backend
- Kein Benutzerkonto
- Kein Cloud-Sync und kein Mehrgerätebetrieb
- Kein Multi-Loaf-Support
- Keine Sensor- oder Thermometer-Integration
- Keine Rezeptdatenbank, Zutatenverwaltung oder Hydrationsberechnung
- Kein Backjournal und keine Statistiken
- Kein Teilen oder Exportieren von Zeitplänen
- Keine Erstellung, Bearbeitung, Duplizierung oder Löschung von Zeitplänen auf der Apple Watch

## Produktprinzipien

- **Phone first:** Das iPhone ist die führende Anwendung und die alleinige Quelle für Zeitpläne und Session-Daten.
- **Watch companion:** Die Apple Watch ist eine reduzierte Begleitoberfläche für laufende Sessions.
- **Single active bake:** Ein Backvorgang genügt; parallele Teige sind bewusst nicht vorgesehen.
- **Zeitplan statt Rezept:** Der Nutzer verwaltet Phasen und Zeiten, nicht Zutatenmengen.
- **Bearbeitbar statt starr:** Alle Zeitwerte und Faltintervalle sind pro Zeitplan anpassbar.
- **Sicher im Hintergrund:** Erinnerungen müssen auch bei gesperrtem Gerät zuverlässig erscheinen.
- **Ruhige Oberfläche:** Eine dominante Hauptaktion pro Screen, wenig visuelle Konkurrenz, klare Sprache.

## Zielnutzer

Hobbybäcker mit Sauerteig, die einen wiederkehrenden Ablauf verlässlich steuern möchten. Sie kennen die grundlegenden Arbeitsschritte und wollen nicht mit vielen Rezeptdetails, Tabellen oder mehreren gleichzeitig laufenden Backprojekten belastet werden.

## Backpfade

Ein Zeitplan hat genau einen Backpfad.

| Pfad | Beschreibung | Typischer Ablauf |
|---|---|---|
| Same-Day | Alle Gärphasen finden überwiegend bei Raumtemperatur statt. | Autolyse, Stockgare mit Faltungen, Formen, Stückgare, Vorheizen, Backen, Auskühlen |
| Overnight: Cold Final Proof | Der Teig wird nach der Stockgare geformt und über Nacht im Kühlschrank geführt. | Autolyse, Stockgare mit Faltungen, Formen, Kühlschrankphase, Vorheizen, Backen, Auskühlen |
| Overnight: Cold Bulk | Der Teig verbringt die Stockgare ganz oder teilweise im Kühlschrank. | Autolyse, kurze Raumtemperaturphase, Kühlschrank-Stockgare, Aufwärmen/Formen, Stückgare, Backen |

Die App soll Cold Final Proof als vorgeschlagene Standard-Overnight-Variante verwenden. Cold Bulk bleibt verfügbar, wird aber als fortgeschrittene Alternative gekennzeichnet.

## Timer-Phasen

Eine Phase beschreibt einen zeitlich abgegrenzten Arbeitsschritt. Sie kann einen Countdown, einen wiederkehrenden Intervall-Reminder oder eine reine manuelle Bestätigung enthalten.

| Phase | Typ | Standardwert | Hinweise |
|---|---:|---:|---|
| Autolyse | Countdown | 30 Minuten | Mehl und Wasser ruhen lassen |
| Mischen | Manuell oder Kurz-Timer | 10 Minuten | Optionaler Arbeitsschritt zum Vermengen der Zutaten |
| Kneten | Countdown | 10 Minuten | Erforderlicher Arbeitsschritt nach dem Mischen |
| Stockgare bei Raumtemperatur | Phasen-Countdown | 4 Stunden | Enthält optional konfigurierbare Falt-Erinnerungen |
| Dehnen & Falten | Intervall-Reminder | 2-mal alle 60 Minuten, erster Reminder nach 60 Minuten | Erinnerungen sind vollständig einstellbar und gehören zur Stockgare |
| Kühlschrank-Stockgare | Zeitfenster | 12 bis 24 Stunden | Cold-Bulk-Pfad; Nutzer definiert Sollzeit sowie optionales Minimum/Maximum |
| Bench Rest | Countdown | 20 Minuten | Ruhezeit zwischen Vorformen und finalem Formen |
| Formen | Countdown | 15 Minuten | Optionaler Schritt zum Formen des Laibs vor der Stückgare oder Kühlschrankphase |
| Stückgare bei Raumtemperatur | Countdown | 90 Minuten | Same-Day oder nach Cold Bulk |
| Cold Final Proof | Zeitfenster | 12 Stunden | Geformter Teig über Nacht im Kühlschrank |
| Ofen vorheizen | Countdown | 45 Minuten | Vor dem Backen |
| Backen mit Deckel | Countdown | 20 Minuten | Temperatur als optionale Notiz, z. B. 250 Grad Celsius |
| Backen ohne Deckel | Countdown | 25 Minuten | Temperatur als optionale Notiz, z. B. 220 Grad Celsius |
| Auskühlen | Countdown | 60 Minuten | Optional überspringbar |

## Konfigurierbares Dehnen & Falten

Dehnen und Falten ist eine **Unterfunktion der Stockgare**, keine eigenständige sequenzielle Hauptphase. Der Nutzer kann diese Erinnerungen für jede Stockgare individuell aktivieren, deaktivieren und konfigurieren.

### Eingaben pro Stockgare

| Einstellung | Bedeutung | Standard | Grenzen für V1 |
|---|---|---:|---:|
| Falt-Erinnerungen aktiv | Schaltet alle Falt-Reminder für diese Stockgare ein oder aus | Ein | Ein/Aus |
| Anzahl `x` | Wie viele Falt-Runden erinnert werden | 4 | 0 bis 12 |
| Intervall `n` | Abstand zwischen zwei Falt-Runden | 30 Minuten | 5 Minuten bis 180 Minuten, in 5-Minuten-Schritten |
| Erste Erinnerung nach | Zeit vom Start der Stockgare bis zur ersten Falt-Runde | 30 Minuten | 0 bis Dauer der Stockgare |
| Erinnerungsart | Bezeichnung der Technik | Dehnen & Falten | Dehnen & Falten, Coil Fold, eigene Bezeichnung |

Die Kernkonfiguration lautet damit: **„x-mal alle n Minuten“**. Beispiel: „4-mal alle 30 Minuten“. Optional kann die erste Erinnerung abweichend konfiguriert werden, etwa „erste Runde nach 45 Minuten, danach 3-mal alle 30 Minuten“.

### Validierungsregeln

- Ist `x = 0` oder sind Falt-Erinnerungen deaktiviert, werden keine Falt-Reminder geplant.
- Die letzte geplante Falt-Runde darf nicht nach dem Ende der Stockgare liegen.
- Falls die Eingabe zu einer Überschreitung führt, zeigt die App unmittelbar eine verständliche Korrektur: „Die letzte Faltung würde nach Ende der Stockgare liegen. Anzahl, Intervall oder Dauer anpassen.“
- Die Anzahl geplanter Falt-Runden wird im Zeitplan und auf der aktiven Timeransicht sichtbar angezeigt.
- Änderungen am gespeicherten Zeitplan wirken nur für zukünftige Sessions. Eine laufende Session kann Falt-Reminder nur über explizite Laufzeitaktionen anpassen.

### Verhalten in der aktiven Session

Bei jeder fälligen Runde:

- Die iPhone-App und, wenn verfügbar, die Apple Watch erinnern: „Jetzt dehnen & falten – Runde 2 von 4.“
- Der Nutzer kann „Erledigt“ wählen.
- Der Nutzer kann „In 10 Minuten erinnern“ wählen.
- Offene Falt-Runden bleiben als nicht erledigt sichtbar, wenn die Stockgare abgeschlossen wird.
- Erledigte und verschobene Falt-Runden werden innerhalb der laufenden Session protokolliert.

## Zeitfenster für Kühlschrankphasen

Kühlschrankphasen sind keine punktgenauen Deadlines. Daher besteht eine Kühlschrankphase aus drei Zeitpunkten:

- **Minimum:** Frühester empfohlener Zeitpunkt für den nächsten Schritt
- **Ziel:** Vom Nutzer geplante Dauer; bei Erreichen wird eine normale Erinnerung gesendet
- **Maximum:** Spätester empfohlener Zeitpunkt; ab hier erscheint eine deutlichere Warnung

Beispiel Cold Final Proof:

- Minimum: 8 Stunden
- Ziel: 12 Stunden
- Maximum: 24 Stunden

Nach Erreichen der Zielzeit zeigt die App nicht „abgelaufen“, sondern: „Backbereit – kann noch bis 08:00 Uhr im Kühlschrank bleiben.“ Bei Überschreiten des Maximums: „Empfohlene Kühlschrankzeit überschritten. Teig prüfen und zeitnah backen.“

## Zeitplan-Modell

Ein Zeitplan ist eine wiederverwendbare Vorlage. Er enthält Konfiguration, aber keinen laufenden Fortschritt.

```swift
struct Schedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?

    var path: BakingPath
    var phases: [PhaseDefinition]
}

enum BakingPath: String, Codable {
    case sameDay
    case coldFinalProof
    case coldBulk
}

struct PhaseDefinition: Identifiable, Codable {
    let id: UUID
    var type: PhaseType
    var title: String
    var duration: TimeInterval?
    var minimumDuration: TimeInterval?
    var maximumDuration: TimeInterval?
    var temperatureCelsius: Int?
    var isEnabled: Bool
    var notes: String?
    var foldConfiguration: FoldConfiguration?
}

struct FoldConfiguration: Codable {
    var isEnabled: Bool
    var technique: FoldTechnique
    var repetitions: Int       // x: Anzahl der Falt-Runden
    var interval: TimeInterval // n: Abstand zwischen Falt-Runden
    var firstReminderOffset: TimeInterval
}

enum FoldTechnique: String, Codable, CaseIterable {
    case stretchAndFold
    case coilFold
    case custom
}

enum PhaseType: String, Codable {
    case autolyse
    case mix
    case kneading
    case bulkRoomTemperature
    case bulkCold
    case benchRest
    case shaping
    case finalProofRoomTemperature
    case coldFinalProof
    case preheat
    case bakeCovered
    case bakeUncovered
    case cooling
    case custom
}
```

### Modellierungsregeln

- Ein Zeitplan enthält eine sortierte Liste von Phasen.
- Die `foldConfiguration` ist nur für eine Stockgare bei Raumtemperatur vorgesehen.
- Phasen können deaktiviert werden, beispielsweise Auskühlen oder Bench Rest.
- Die Reihenfolge ist in V1 durch den gewählten Pfad vorgegeben; Nutzer können Zeiten ändern und optionale Phasen ein- oder ausschalten.
- Benutzerdefinierte Phasen sind optional für V1. Falls umgesetzt, bestehen sie mindestens aus Name und Dauer.
- Temperaturen sind Notizen für den Nutzer, keine gesteuerten Geräteeinstellungen.

## Aktiver Backvorgang

Ein aktiver Backvorgang ist eine Momentaufnahme eines gestarteten Zeitplans. Änderungen am gespeicherten Zeitplan dürfen einen laufenden Backvorgang nicht nachträglich verändern.

```swift
struct BakingSession: Identifiable, Codable {
    let id: UUID
    let scheduleID: UUID
    let scheduleName: String
    let startedAt: Date

    var status: SessionStatus
    var phases: [SessionPhase]
    var activePhaseIndex: Int?
    var pausedAt: Date?
    var totalPausedDuration: TimeInterval
}

enum SessionStatus: String, Codable {
    case planned
    case active
    case paused
    case completed
    case cancelled
}

struct SessionPhase: Identifiable, Codable {
    let id: UUID
    var definition: PhaseDefinition
    var status: PhaseStatus
    var startedAt: Date?
    var completedAt: Date?
    var effectiveDuration: TimeInterval?
    var manualAdjustment: TimeInterval
    var foldRounds: [FoldRound]
}

struct FoldRound: Identifiable, Codable {
    let id: UUID
    var number: Int
    var scheduledAt: Date
    var status: FoldRoundStatus
    var completedAt: Date?
    var postponedBy: TimeInterval
}

enum FoldRoundStatus: String, Codable {
    case pending
    case due
    case completed
    case postponed
    case skipped
}

enum PhaseStatus: String, Codable {
    case pending
    case active
    case paused
    case completed
    case skipped
}
```

## Timer-Verhalten

### Grundsatz

Die App darf sich nicht auf einen im Vordergrund laufenden Sekundentimer als Wahrheitsquelle verlassen. Maßgeblich sind gespeicherte Zeitstempel.

Für eine aktive Phase wird gespeichert:

- Startzeitpunkt
- geplante Dauer
- aufsummierte Pausendauer
- manuelle Verlängerung oder Verkürzung

Die verbleibende Zeit wird aus der aktuellen Uhrzeit berechnet:

\[
verbleibend = geplante\ Dauer + Anpassungen - (jetzt - Startzeit - Pausenzeit)
\]

Beim erneuten Öffnen der App wird der Zustand aus diesen Daten rekonstruiert. Das ist wichtig, weil iOS Hintergrundausführung zeitlich begrenzt und nicht für sekundengenau fortlaufende App-Logik gedacht ist.

### Phasenabschluss

Beim Ende eines Countdowns:

1. Lokale Benachrichtigung auslösen.
2. In der App den Abschlusszustand sichtbar machen.
3. Den Nutzer explizit „Nächste Phase starten“ lassen.
4. Nicht automatisch in die nächste handwerkliche Phase wechseln.

Ausnahme: Die zweite Backphase kann optional direkt nach Ende der ersten Backphase starten, weil der Übergang zeitkritisch ist. Diese Automatik wird pro Zeitplan konfigurierbar gemacht und ist standardmäßig aktiviert.

### Pausieren

- Pausieren ist für jede Countdown-Phase erlaubt.
- Beim Pausieren werden keine Zeitwerte überschrieben; es wird ein Pausenzeitstempel gesetzt.
- Beim Fortsetzen wird die Pausendauer kumuliert.
- Eine pausierte Phase löst keine ausstehende Abschlussbenachrichtigung aus.

### Verlängern und Verkürzen

- Schnellaktionen: +5 Minuten, +15 Minuten, +30 Minuten, +1 Stunde.
- Für Kühlschrankphasen zusätzlich: +2 Stunden und +4 Stunden.
- Optional: „Jetzt beenden“ für jede Phase.
- Verkürzen soll über „Jetzt abschließen“ oder über einen editierbaren Wert möglich sein; negative Restzeit wird nie angezeigt.

### Nicht erledigte Schritte

- Eine Phase wird mit „Erledigt“ abgeschlossen, sobald der Nutzer zum nächsten Schritt weitergeht.
- Nicht erledigte Untertimer und Falt-Runden bleiben in der Timeline als offene Historie sichtbar.
- Nach dem Abschluss einer Phase werden für deren offene Erinnerungen keine weiteren Benachrichtigungen geplant.

### Falt-Intervalle

Falt-Erinnerungen gehören fachlich zur Stockgare und erzeugen keine eigene sequenzielle Hauptphase.

Beispiel: Stockgare vier Stunden; `x = 4`; `n = 30 Minuten`; erste Erinnerung nach 30 Minuten. Die App plant Falt-Runden für 00:30, 01:00, 01:30 und 02:00 nach Beginn der Stockgare.

Eine Falt-Runde ist ein eigenständiges, persistent gespeichertes Ereignis der laufenden Session. Damit bleibt ihr Status nach App-Neustart, nach einer Verschiebung oder bei Interaktion über die Apple Watch korrekt nachvollziehbar.

## Benachrichtigungen

Die App nutzt ausschließlich lokale iOS-Benachrichtigungen. Vor dem ersten Start eines Backvorgangs fragt sie nach der Benachrichtigungsberechtigung.

### Benachrichtigungstypen

| Ereignis | Standardtext |
|---|---|
| Phase abgeschlossen | „Autolyse beendet. Als Nächstes: Teig mischen.“ |
| Falt-Erinnerung | „Jetzt dehnen & falten – Runde 2 von 4.“ |
| Kühlschrank-Zielzeit erreicht | „Der Teig ist backbereit und kann noch bis 08:00 Uhr im Kühlschrank bleiben.“ |
| Kühlschrank-Maximum erreicht | „Die empfohlene Kühlschrankzeit ist überschritten. Teig prüfen und zeitnah backen.“ |
| Vorheizen abgeschlossen | „Ofen ist vorgeheizt. Jetzt einschneiden und backen.“ |
| Backphase 1 abgeschlossen | „Deckel abnehmen und Phase 2 starten.“ |
| Auskühlen abgeschlossen | „Das Brot kann angeschnitten werden.“ |

### Anforderungen

- Beim Start, Pausieren, Fortsetzen, Verlängern, Überspringen oder Abschließen einer Phase werden offene Benachrichtigungen dieser Phase gelöscht und neu geplant.
- Benachrichtigungen müssen eindeutig einer Session und Phase zuordenbar sein.
- Der Nutzer kann in den iPhone-Einstellungen Ton und haptisches Feedback ein- oder ausschalten.
- Ein optionaler Schlafmodus unterdrückt nicht kritische Falt-Erinnerungen in einem konfigurierten Zeitfenster. Abschluss- und Maximalzeitwarnungen bleiben aktiv.

## Apple-Watch-App

### Rolle und Abgrenzung

Die Watch-App ist eine **reduzierte Begleit-App**. Sie wird ausschließlich für eine laufende oder pausierte Session verwendet. Das iPhone bleibt die führende Quelle für Zeitpläne, Session-Konfiguration, Timerberechnung und Persistenz.

Auf der Apple Watch sind ausdrücklich nicht möglich:

- Zeitpläne erstellen
- Zeitpläne bearbeiten
- Zeitpläne duplizieren oder löschen
- Backpfade wechseln
- Faltkonfiguration ändern
- Rückwärtsplanung erstellen
- Einstellungen bearbeiten

### Watch-Funktionen

| Funktion | Verhalten |
|---|---|
| Aktuelle Phase anzeigen | Name, Icon, Status und verbleibende Zeit |
| Nächste Phase anzeigen | Name und geplante Dauer als Vorschau |
| Fortschritt anzeigen | Aktuelle Hauptphase relativ zur Gesamtzahl der Hauptphasen |
| Falt-Runde anzeigen | „Runde 2 von 4“ sowie Zeitpunkt oder Status |
| Erinnerungen erhalten | Haptische und visuelle Benachrichtigungen für Phasen und Faltungen |
| Phase pausieren/fortsetzen | Schnellaktion; wird an das iPhone übertragen |
| Phase verlängern | Schnellaktion für +5 Minuten und +15 Minuten; bei Kühlschrankphasen zusätzlich +1 Stunde |
| Phase abschließen | Schnellaktion mit Bestätigung bei handwerklichen Schritten |
| Falt-Runde erledigen | „Erledigt“ markiert die aktuell fällige Runde |
| Falt-Runde verschieben | „+10 Minuten“ verschiebt die aktuell fällige Runde |

### Watch-Ansichten

#### Aktive Phase

Die primäre Watch-Ansicht zeigt:

- SF Symbol der Phase
- Titel der aktuellen Phase
- großen Countdown oder Status „Backbereit“
- eine Hauptaktion: Pause, Fortsetzen oder Abschließen
- sekundäre Schnellaktion: +5 Minuten

Die Ansicht soll ohne Scrollen die wichtigste Information vermitteln.

#### Falt-Erinnerung

Wenn während einer Stockgare eine Falt-Runde fällig ist, steht die Handlung im Vordergrund:

- „Dehnen & Falten“
- „Runde 2 von 4“
- Buttons: „Erledigt“, „+10 Min.“
- Optional: „Rest überspringen“ in einer sekundären Ansicht mit Bestätigung

#### Nächster Schritt

Eine kompakte Detailansicht zeigt den Namen der nächsten Hauptphase und deren Dauer. Sie dient nur der Orientierung und verändert keine Planung.

### Kommunikation iPhone und Watch

- Die iPhone-App führt die vollständige Session und persistiert sie lokal.
- Die Watch erhält einen kompakten Snapshot der aktiven Session: aktuelle Phase, Restzeit, Status, nächste Phase, Falt-Runden und erlaubte Aktionen.
- Schnellaktionen der Watch werden an die iPhone-App übertragen und dort validiert sowie dauerhaft gespeichert.
- Ist das iPhone temporär nicht erreichbar, zeigt die Watch den zuletzt synchronisierten Status an und kennzeichnet ihn optional als „letzte Aktualisierung“. Schreibende Aktionen werden nach Möglichkeit in eine lokale Queue gelegt und beim nächsten Erreichen des iPhones übertragen.
- Konfliktregel: Das iPhone ist autoritativ. Bei widersprüchlichen Aktionen entscheidet die zuletzt erfolgreich auf dem iPhone verarbeitete Aktion.

### Watch-Benachrichtigungen

- Bei fälligen Falt-Runden und Phasenenden soll die Watch eine haptische Erinnerung erhalten, sofern sie getragen und erreichbar ist.
- Die Benachrichtigung enthält nur die Aktion und den Kontext, z. B. „Jetzt dehnen & falten – Runde 3 von 4“.
- Auf Benachrichtigungen können, soweit technisch verfügbar, die Schnellaktionen „Erledigt“ und „+10 Min.“ angeboten werden.
- Das iPhone plant die maßgeblichen lokalen Benachrichtigungen. Die Watch nutzt die Weiterleitung beziehungsweise die Watch-spezifische Darstellung der Benachrichtigung.

### Anforderungen an Robustheit

- Die Watch-App darf keine eigene, abweichende Timerwahrheit führen.
- Nach dem Öffnen der Watch-App muss der Countdown aus dem zuletzt bekannten Startzeitpunkt und der aktuellen Zeit berechnet werden.
- Nach Rückkehr einer Verbindung muss ein frischer Snapshot vom iPhone angefordert werden.
- Wenn keine aktive Session existiert, zeigt die Watch eine Leerseite: „Kein Backvorgang aktiv. Starte einen Zeitplan auf dem iPhone.“

## Rückwärtsplanung

Der Nutzer kann auf dem iPhone wählen: „Ich möchte um [Datum/Uhrzeit] backen.“ Die App berechnet rückwärts einen Vorschlag für den Beginn.

### Regel

Die gewählte Backzeit ist der Start von „Backen mit Deckel“, nicht der Zeitpunkt eines fertigen oder abgekühlten Brots. Das reduziert Mehrdeutigkeit.

### Berechnung

- Alle verpflichtenden vorangehenden Phasen werden addiert.
- Bei Kühlschrankphasen wird die Zielzeit verwendet.
- Optional kann der Nutzer „Brot fertig zum Anschneiden“ wählen; dann werden Backzeit und Auskühlzeit zusätzlich rückwärts gerechnet.
- Die App zeigt das Ergebnis als Vorschlag und lässt die einzelnen Zeiten weiterhin bearbeiten.

Beispiel für Cold Final Proof: gewünschter Backbeginn morgen 08:00 Uhr, Cold Final Proof 12 Stunden, Formen 15 Minuten, Stockgare vier Stunden, Autolyse 30 Minuten. Die App berechnet daraus den empfohlenen Startzeitpunkt und zeigt die komplette Timeline.

## Informationsarchitektur

Die iPhone-App hat drei primäre Bereiche.

### Zeitpläne

Startansicht mit gespeicherten Zeitplänen.

- Titel: „Zeitpläne“
- Primäre Aktion: „Neuer Zeitplan“
- Jede Kartenzeile zeigt Name, Pfad und typische Gesamtdauer
- Sekundäre Aktion: Duplizieren
- Swipe-Aktion: Löschen
- Tap: Detailansicht
- Leerer Zustand: kurze Erklärung plus „Ersten Zeitplan erstellen“

### Aktiver Timer

Wenn keine Session aktiv ist, zeigt der Tab eine ruhige Leerseite mit Verweis auf Zeitpläne. Wenn eine Session aktiv ist, zeigt er nur den aktuellen Kontext:

- Phasenname und passendes SF Symbol
- großer Countdown oder Status „Backbereit“
- bei Kühlschrankphase: Minimum, Ziel und Maximum als klarer Zeitstatus
- Fortschrittsanzeige über die Hauptphasen
- nächste Phase als dezente Vorschau
- Aktionen: Pause/Fortsetzen, +Zeit, Abschließen
- bei laufender Stockgare: nächste Faltzeit, konfigurierte Anzahl und erledigte Runden

### Einstellungen

- Benachrichtigungen aktivieren/deaktivieren
- Ton aktivieren/deaktivieren
- Haptik aktivieren/deaktivieren
- Schlafmodus einrichten
- Standarddauer für neue Zeitpläne
- Datenschutzhinweis: „Alle Daten bleiben auf diesem iPhone.“

## Zeitplan erstellen und bearbeiten

### Erstellfluss

1. Nutzer tippt „Neuer Zeitplan“.
2. Nutzer vergibt einen Namen.
3. Nutzer wählt den Pfad: Same-Day, Overnight im Kühlschrank nach dem Formen oder Cold Bulk.
4. App erzeugt einen passenden Satz von Standardphasen.
5. Nutzer prüft und verändert bei Bedarf die Dauer jeder Phase.
6. Bei einer Raumtemperatur-Stockgare konfiguriert der Nutzer optional Dehnen & Falten als „x-mal alle n Minuten“.
7. Nutzer tippt „Speichern“.

### Bearbeitungsansicht

- Vertikale Timeline statt Tabellenformular
- Jede Phase als Card: Icon, Titel, Dauer, optional Temperatur und kurze Notiz
- Tippen auf Card öffnet eine Detailansicht oder Inline-Editor
- Dauer über Picker in Minuten/Stunden einstellen
- Bei Kühlschrankphase getrennte Eingabe für Minimum, Ziel und Maximum
- Bei Stockgare ein eigener Bereich „Dehnen & Falten“ mit: Aktivierung, Technik, `x` Runden, `n` Minuten Intervall und optionalem Offset für die erste Runde
- Deaktivierbare optionale Schritte: Bench Rest, Auskühlen
- Speicherung erst bei explizitem „Speichern“; Abbrechen verwirft Änderungen

## Clean-UI-Richtlinien

- Großzügige vertikale Abstände, maximal eine Akzentfarbe.
- Systemfarben und Dynamic Type vollständig unterstützen.
- SF Symbols verwenden, keine dekorativen Illustrationen in V1.
- Aktive Aktion visuell dominant; destruktive Aktionen nur sekundär.
- Zeitformat stets lokalisiert, in Deutschland standardmäßig 24-Stunden-Format.
- Countdown in Monospace-Ziffern, damit sich die Anzeige ruhig aktualisiert.
- Keine permanenten technischen Begriffe: „Kühlschrankphase“ oder „Overnight im Kühlschrank“ statt ausschließlich „Cold Retard“.
- Statusfarben zusätzlich immer mit Text und Symbol ausdrücken; nicht nur Farbe verwenden.
- Die Watch-App folgt denselben Begriffs- und Statuskonventionen, reduziert Inhalte aber auf die aktuelle Entscheidung.

## Persistenz und lokale Architektur

### Technische Entscheidungen

- SwiftUI für die iPhone- und Watch-Oberfläche.
- SwiftData für lokale Persistenz auf dem iPhone ab iOS 17.
- `UserDefaults` nur für globale Einstellungen wie Schlafmodus oder Standardwerte.
- `UNUserNotificationCenter` für lokale iPhone-Erinnerungen.
- `WatchConnectivity` für die Synchronisation einer aktiven Session und die Übertragung von Watch-Schnellaktionen.
- Keine Netzwerkzugriffe erforderlich oder vorgesehen.

SwiftData speichert Zeitpläne und Sessions dauerhaft auf dem iPhone. Das Datenmodell muss so ausgelegt sein, dass eine laufende Session nach App-Neustart oder Geräte-Sperre vollständig rekonstruiert werden kann.

Die Watch speichert höchstens einen kompakten, ersetzbaren Session-Snapshot für die Anzeige bei kurzzeitiger Verbindungsunterbrechung. Sie ist keine zweite, vollständige Persistenzschicht für Zeitpläne.

### Empfohlene SwiftData-Entitäten

- `ScheduleEntity`
- `PhaseDefinitionEntity`
- `BakingSessionEntity`
- `SessionPhaseEntity`
- `FoldRoundEntity`

`ScheduleEntity` und `BakingSessionEntity` sind getrennt. Beim Start einer Session werden die Phasendefinitionen kopiert; dadurch kann der Nutzer die Vorlage später bearbeiten, ohne die laufende Session zu verändern.

### Datenlebenszyklus

- Zeitpläne bleiben erhalten, bis der Nutzer sie löscht.
- Abgeschlossene und abgebrochene Sessions können in V1 automatisch nach 30 Tagen gelöscht werden oder sofort verworfen werden. Da ein Backjournal außerhalb des Scopes liegt, ist eine dauerhafte Historie nicht notwendig.
- Eine aktive Session darf nicht automatisch gelöscht werden.
- Beim Löschen eines Zeitplans mit aktiver Session erscheint ein Hinweis; die aktive Session bleibt als Snapshot erhalten.

## Zustandsmodell

### Session-Zustände

```text
planned -> active -> paused -> active
planned -> cancelled
active -> completed
active -> cancelled
paused -> cancelled
```

### Phasen-Zustände

```text
pending -> active -> paused -> active -> completed
pending -> skipped
active -> skipped
```

### Falt-Runden-Zustände

```text
pending -> due -> completed
pending -> due -> postponed -> due
pending -> skipped
Due -> skipped
```

### Zustandsregeln

- Es existiert maximal eine Session mit Status `active` oder `paused`.
- In einer aktiven Session ist maximal eine Hauptphase `active` oder `paused`.
- Falt-Runden sind untergeordnete Ereignisse der aktiven Stockgare und haben einen separaten, persistenten Status.
- Eine abgeschlossene Hauptphase kann in V1 nicht erneut geöffnet werden; bei Fehlern kann der Nutzer die nächste Phase überspringen oder den gesamten Prozess abbrechen.
- Eine Watch-Schnellaktion wird erst wirksam dargestellt, wenn sie vom iPhone bestätigt und in der Session gespeichert wurde.

## Fehlerfälle und Sonderfälle

| Fall | Erwartetes Verhalten |
|---|---|
| App wird beendet | Beim nächsten Öffnen wird Restzeit aus Zeitstempeln berechnet |
| Gerät war gesperrt | Lokale Benachrichtigung informiert; App rekonstruiert beim Öffnen den aktuellen Status |
| Phase ist überfällig | Status „seit X Minuten beendet“; Nutzer kann abschließen, verlängern oder nächste Phase starten |
| Kühlschrank-Zielzeit überschritten | Status „Backbereit seit X“; bis Maximum keine Fehlermeldung |
| Kühlschrank-Maximum überschritten | Warnhinweis, aber kein automatischer Abbruch |
| Benachrichtigungen nicht erlaubt | Persistenter, nicht blockierender Hinweis in der aktiven iPhone-Ansicht |
| Zeitzonenwechsel | Alle Zeitpunkte basieren auf `Date`; Anzeige passt sich lokaler Zeitzone an |
| Gerätezeit manuell geändert | App berechnet anhand der neuen Systemzeit und weist bei großen Abweichungen auf mögliche Ungenauigkeit hin |
| Zweiter Zeitplan soll starten | App weist darauf hin, dass zuerst die laufende Session abgeschlossen oder abgebrochen werden muss |
| Faltplan passt nicht in Stockgare | Speichern wird verhindert, bis Anzahl, Intervall, Offset oder Stockgare korrigiert wurden |
| Apple Watch nicht verbunden | iPhone funktioniert vollständig weiter; Watch zeigt beim nächsten Öffnen den letzten Snapshot oder fordert Verbindung an |
| Watch-Aktion bei fehlender Verbindung | Aktion wird als ausstehend angezeigt und bei erneuter Verbindung übertragen; bis zur iPhone-Bestätigung bleibt der alte Status sichtbar |
| Gleichzeitige Aktion auf iPhone und Watch | Das iPhone verarbeitet Aktionen serialisiert; die zuletzt erfolgreich gespeicherte Aktion bestimmt den finalen Zustand |

## Akzeptanzkriterien

### Zeitpläne

- Ein Nutzer kann einen Same-Day- und zwei Overnight-Zeitplanvarianten erstellen und lokal speichern.
- Nach vollständigem Beenden und erneuten Starten der App sind gespeicherte Zeitpläne vorhanden.
- Ein Zeitplan kann bearbeitet, dupliziert und gelöscht werden.
- Ein Zeitplan kann nur gestartet werden, wenn keine weitere aktive oder pausierte Session besteht.

### Konfigurierbares Dehnen & Falten

- Der Nutzer kann für jede Raumtemperatur-Stockgare Falt-Erinnerungen an- und ausschalten.
- Der Nutzer kann die Anzahl `x` und das Intervall `n` getrennt einstellen, z. B. „4-mal alle 30 Minuten“.
- Die App verhindert, dass die letzte Falt-Runde nach Ende der Stockgare geplant wird.
- Die aktive Session zeigt erledigte und verbleibende Falt-Runden an.
- Eine fällige Runde kann als erledigt markiert oder um zehn Minuten verschoben werden.
- Nach Abschluss oder Abbruch der Stockgare werden alle offenen Falt-Benachrichtigungen entfernt.

### Aktive Session

- Nach dem Start ist die erste aktive Phase sichtbar, einschließlich Startzeit, Restzeit und nächstem Schritt.
- Nach App-Neustart wird die Restzeit korrekt aus gespeicherten Zeitstempeln berechnet.
- Pausieren und Fortsetzen verändert die Restzeit korrekt.
- Verlängerungen sind sofort in UI und in der geplanten Benachrichtigung sichtbar.
- Nicht erledigte Falt-Runden bleiben in der Timeline sichtbar und werden nicht als erledigt gezählt.

### Kühlschrankphasen

- Der Nutzer kann Minimum, Ziel und Maximum getrennt konfigurieren.
- Beim Minimum zeigt die App „frühestens bereit“.
- Beim Ziel wird eine normale „backbereit“-Erinnerung gesendet.
- Beim Maximum wird eine Warnung gesendet.
- Der Nutzer kann die Kühlschrankphase unkompliziert um Stunden verlängern.

### Apple Watch

- Bei einer aktiven oder pausierten Session zeigt die Watch aktuelle Phase, Restzeit und nächste Phase.
- Bei fälligen Falt-Runden erhält der Nutzer auf der Watch eine haptische Erinnerung.
- Der Nutzer kann auf der Watch eine Falt-Runde als erledigt markieren oder um zehn Minuten verschieben.
- Der Nutzer kann auf der Watch eine Phase pausieren, fortsetzen, um eine erlaubte Dauer verlängern oder abschließen.
- Nach einer Watch-Aktion aktualisieren iPhone und Watch den gleichen, persistierten Session-Stand.
- Ohne aktive Session zeigt die Watch keine Zeitplanverwaltung, sondern nur den Hinweis, einen Backvorgang auf dem iPhone zu starten.
- Auf der Watch existiert keine Möglichkeit, einen Zeitplan zu erstellen oder zu bearbeiten.

## Implementierungsstand und Produktabgleich

### Bereits implementiert

Der aktuelle App-Stand deckt folgende Kernbereiche ab:

- Lokale iPhone-App mit SwiftUI und SwiftData; Zeitpläne und laufende Sessions werden dauerhaft auf dem Gerät gespeichert.
- Drei Vorlagenpfade: Same-Day, Overnight mit Cold Final Proof und Cold Bulk. Die Vorlagen erzeugen passende Standardphasen.
- Zeitplanliste mit Erstellen, Bearbeiten, Duplizieren und Löschen. Beim Löschen bleibt eine laufende Session als unabhängiger Snapshot erhalten.
- Phasen-Editor mit Aktivierung/Deaktivierung, Dauer, Mindest-/Ziel-/Maximaldauer für kalte Phasen, Temperaturhinweis, Notizen und eigener Bezeichnung.
- Faltkonfiguration für die Raumtemperatur-Stockgare mit Technik, Anzahl, Intervall, erstem Offset und Validierung gegen die Phasendauer.
- Wiederverwendbare Sub-Timer innerhalb von Stückgare, Cold Final Proof und Backen. Unterstützt werden Start nach Phasenbeginn, Verkettung mit dem vorherigen Sub-Timer und Start vor Phasenende. Beispiele sind Vorheizen, Deckel abnehmen, Dampf ablassen und Temperatur senken.
- Eine laufende oder geplante Session gleichzeitig. Eine geplante Session startet zur geplanten Zeit über lokale Erinnerung oder manuell über die App.
- Timestamp-basierte Timerberechnung mit Pausieren, Fortsetzen, Verlängern, Abschließen, Überspringen und explizitem Start der nächsten Phase. Frühzeitiges Abschließen kann eine Anpassung des verbleibenden Plans anbieten.
- Falt-Runden und Sub-Timer werden als eigene Session-Ereignisse persistent gespeichert und können nach einem Neustart aktualisiert beziehungsweise erledigt werden.
- Lokale Benachrichtigungen werden nach Sessionänderungen vollständig neu geplant. Falt- und Sub-Timer können im Schlafmodus unterdrückt werden; Phasenende und Kühlschrank-Maximum bleiben kritisch.
- Rückwärtsplanung mit zwei Zielen: Beginn der Backphase oder „bereit zum Anschneiden“. Für Kühlschrankphasen werden empfohlener Start sowie frühester und spätester Start berechnet.
- Live Activity und Dynamic Island auf dem iPhone mit aktueller Phase, Zielzeit, nächstem Sub-Timer, nächster Phase und Pausenstatus.
- Apple-Watch-Begleit-App mit aktuellem Snapshot, Phase, Zielzeit, nächstem Schritt, Pause/Fortsetzen, Abschließen, +5 Minuten sowie Falt-Runde erledigen/+10 Minuten. Aktionen werden auf dem iPhone validiert und gespeichert.
- Einstellungen für Benachrichtigungen, Ton, Haptik, Schlafmodus und die Frage nach einer Plananpassung bei vorzeitigem Abschluss. Auf iOS 26 ist AlarmKit als alternative Zustellung integriert.

### Teilweise implementiert oder vom ursprünglichen Ziel abweichend

- **Countdown-Darstellung:** Die fachliche Wahrheit ist timestamp-basiert, die iPhone-Ansicht zeigt jedoch je nach Phase auch Zielzeit/Status statt eines permanent großen Sekunden-Countdowns. Die PRD-Anforderung sollte daher „Restzeit oder klare Zielzeit/Statusanzeige“ lauten.
- **Manuelle Phasen:** Manuelle Schritte werden über eine Phase ohne Dauer unterstützt, aber nicht als eigener, besonders formulierter Bestätigungstyp modelliert. Die UI muss weiterhin klar zwischen „manuell erledigen“ und „Countdown beendet“ unterscheiden.
- **Cold-Phase-Minimum:** Minimum, Ziel und Maximum sind modelliert und werden für Planung, Status und Warnungen genutzt. Die Benachrichtigung am Minimum ist derzeit kein eigener Benachrichtigungstyp; die UX muss den Zustand in der aktiven Ansicht trotzdem eindeutig darstellen.
- **Watch-Erreichbarkeit:** Der Snapshot-Transport ist vorhanden. Eine ausstehende Offline-Aktionswarteschlange, eine sichtbare letzte Aktualisierungszeit und eine bestätigte Aktion sind noch nicht vollständig umgesetzt. Ist das iPhone nicht erreichbar, verwirft die Watch Schreibaktionen derzeit.
- **Watch-Erinnerungen:** Die Watch erhält den iPhone-Snapshot; eine eigenständige, nachweisbar haptische Watch-Benachrichtigungsplanung ist nicht als eigene Logik vorhanden und muss auf realen Geräten verifiziert werden.
- **AlarmKit:** AlarmKit ist nur unter iOS 26 verfügbar und benötigt eine separate Autorisierung. Auf älteren Systemen bleibt die App bei lokalen Benachrichtigungen.
- **Lokalisierung:** Das Projekt enthält String Catalogs und deutsche Übersetzungsgrundlagen, aber die sichtbaren Oberflächen sind noch nicht vollständig sprachlich vereinheitlicht. Vor Release ist ein vollständiger Lokalisierungs- und Copy-Durchlauf erforderlich.

### Offene Produkt- und Qualitätsentscheidungen

- **Session-Historie:** Abgeschlossene Sessions werden aktuell nicht als Journal genutzt. Es muss vor dem Release entschieden werden, ob sie sofort verworfen oder nach einer definierten Aufbewahrungszeit gelöscht werden.
- **Terminierte Sessions:** Eine geplante Session darf in der aktiven Session-Ansicht nicht wie eine laufende Session wirken. Startzeit, Abbruch und Ersetzen müssen als eigener Zustand getestet werden.
- **Benachrichtigungsberechtigung:** Bei verweigerter Berechtigung braucht die aktive Ansicht einen klaren, nicht blockierenden Hinweis mit direktem Weg zu den Systemeinstellungen.
- **Planänderung:** Das frühzeitige Abschließen einer Phase kann den nachfolgenden Plan verschieben. Dieser Dialog, die daraus entstehenden Benachrichtigungen und die Timeline müssen als zusammenhängender Ablauf getestet werden.
- **Sub-Timer-Definition:** Sub-Timer sind jetzt ein Kernbestandteil der Backphase. Sie müssen in der Terminologie, im Datenmodell und in der Akzeptanzprüfung ausdrücklich neben Falt-Runden geführt werden.
- **Geräte- und Lifecycle-Tests:** Hintergrund, Gerätesperre, App-Neustart, Zeitzonenwechsel, Sommer-/Winterzeit, fehlende Watch-Verbindung und Wiederherstellung einer Live Activity benötigen einen Testlauf auf echten Geräten beziehungsweise Simulatoren.

### Aktualisierte Produktregeln

1. Die iPhone-App bleibt die autoritative Quelle für Zeitplan, Session, Timerzustand und Watch-Aktionen.
2. Eine Session besteht aus sequenziellen Hauptphasen. Falt-Runden und Sub-Timer sind untergeordnete Ereignisse und dürfen den Hauptphasenindex nicht verändern.
3. Der Nutzer startet die nächste Hauptphase explizit. Die einzige geplante Ausnahme ist der konfigurierbare automatische Übergang zwischen den beiden Backphasen.
4. Eine kalte Phase hat mindestens die Zustände „noch nicht bereit“, „frühestens bereit“, „empfohlen bereit“ und „Zeitfenster überschritten“. Diese Zustände werden mit Text und Symbol, nicht nur mit Farbe, kommuniziert.
5. Jede Session-Mutation muss persistiert und anschließend für lokale Benachrichtigungen, Live Activity und Watch-Snapshot repliziert werden.
6. Ein Zeitplan ist eine Vorlage. Beim Start wird eine unveränderliche Session-Projektion erzeugt; spätere Vorlagenänderungen dürfen die laufende Session nicht verändern.
7. Neue V1-Funktionen dürfen nicht Cloud-Sync, Konto, Rezeptverwaltung, Multi-Loaf oder parallele Sessions voraussetzen.

### Aktualisierte Release-Akzeptanz

- Alle drei Pfade lassen sich als Vorlage erzeugen, bearbeiten, duplizieren, speichern, starten und löschen.
- Eine laufende Session kann nach App-Neustart, Gerätesperre und Lifecycle-Wechsel korrekt fortgesetzt werden; die Session bleibt unabhängig von der Vorlage.
- Jede Phasenänderung aktualisiert UI, Persistenz, lokale Benachrichtigungen, Live Activity und – sofern verbunden – den Watch-Snapshot.
- Falt-Runden und Sub-Timer zeigen ihren Status in der Session-Timeline und erzeugen keine zusätzliche Hauptphase.
- Cold-Phase-Status und Ziel-/Maximalwarnung sind in iPhone-Ansicht, Benachrichtigung und Live Activity konsistent.
- Rückwärtsplanung zeigt Ziel, empfohlenen Start sowie die Zeitfenster-Spanne und erzeugt höchstens eine geplante Session.
- Watch-Aktionen werden nur nach iPhone-seitiger Verarbeitung als bestätigt dargestellt; Offline-Verhalten ist entweder als Queue umgesetzt oder klar als nicht verfügbar gekennzeichnet.
- Die App funktioniert ohne Netzwerk und ohne Watch. Keine optionale Integration darf den iPhone-Kernablauf blockieren.

## Aktualisierte Umsetzungsreihenfolge

1. Release-Härtung des vorhandenen Kerns: Lifecycle, Session-Wiederherstellung, Benachrichtigungsberechtigungen, frühzeitiges Abschließen und geplante Sessions.
2. Sub-Timer als sichtbaren Bestandteil des PRD-, UI- und Testmodells dokumentieren und durchgängig verifizieren.
3. Cold-Phase-Minimum, Ziel und Maximum auf iPhone, Benachrichtigungen, Live Activity und Watch sprachlich und fachlich angleichen.
4. Watch-Verbindungszustände vervollständigen: letzte Aktualisierung, Offline-Hinweis, bestätigte Aktionen und – falls gewünscht – Aktionswarteschlange.
5. Lokalisierung, Accessibility, Dynamic Type und Copy der sichtbaren Oberflächen abschließen.
6. AlarmKit auf iOS 26 als optionale Zustellung auf realen Geräten testen; lokale Benachrichtigungen als Fallback verifizieren.
7. Release-Abnahme mit Unit-, UI-, Simulator- und mindestens einem Hintergrund-/Gerätesperrtest durchführen.

## Spätere Erweiterungen (außerhalb V1)

- Multi-Loaf und parallele Sessions
- Erweiterte Live-Activity-Interaktionen und mehr kontextuelle Aktionen
- iCloud-Sync und Gerätewechsel
- Backjournal mit Fotos und Notizen
- Rezeptverwaltung und Mengenrechner
- Sensoranbindung für Teig- oder Kühlschranktemperatur
- Import, Export und Teilen von Zeitplänen
