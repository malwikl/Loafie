# Loafie

Loafie ist eine native iOS-App zum Planen und Durchführen von Sauerteig-Backvorgängen. Backpläne bestehen aus zeitlich geplanten Schritten und optionalen Erinnerungen. Ein laufender Backvorgang kann pausiert, verlängert und auf dem iPhone, in einer Live Activity oder auf der Apple Watch verfolgt werden.

## Funktionen

- Backpläne mit mehreren Schritten erstellen und bearbeiten
- Zeitbasierte und manuelle Schritte mit Notizen verwalten
- Schritt-Erinnerungen konfigurieren, einschließlich Temperatur-Erinnerungen
- Dehnen-und-Falten-Erinnerungen mit Intervall, Technik und Rundenzahl planen
- Aktive Backvorgänge mit Pause, Fortsetzen, Verlängern, Überspringen und Abschließen steuern
- Lokale Mitteilungen und – auf kompatiblen Systemen – AlarmKit verwenden
- Laufende Backvorgänge als Live Activity auf dem Sperrbildschirm anzeigen
- Aktuellen Backvorgang über die Apple Watch anzeigen und steuern
- Backpläne und Backvorgänge mit SwiftData dauerhaft speichern
- Deutsche Lokalisierung und ein warmes Sauerteig-Designsystem

## Voraussetzungen

- macOS mit Xcode 26 oder neuer
- iOS 18 oder neuer für die Haupt-App
- watchOS 10 oder neuer für die Apple-Watch-App
- Ein Apple-Entwicklerkonto für die Installation auf einem physischen Gerät

Die Live-Activity-Extension unterstützt iOS 16.1 oder neuer. Einige Funktionen wie AlarmKit sind nur verfügbar, wenn das Betriebssystem sie unterstützt.

## Projekt öffnen

```bash
open Loafie.xcodeproj
```

In Xcode das Schema `Loafie` auswählen. Für ein physisches Gerät müssen Team und automatische Signierung in den Target-Einstellungen konfiguriert sein.

## Bauen

Für den iOS-Simulator:

```bash
xcodebuild \
  -project Loafie.xcodeproj \
  -scheme Loafie \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Für ein verbundenes iPhone kann das Projekt direkt aus Xcode gebaut und installiert werden. Alternativ erzeugt Xcode mit dem Schema `Loafie` ein signiertes `Loafie.app` für das gewählte Gerät.

## Tests

Die Unit-Tests decken unter anderem Timerberechnung, Backplan-Validierung, Erinnerungsplanung, Persistenz, Sessions und WatchConnectivity ab.

```bash
xcodebuild \
  -project Loafie.xcodeproj \
  -scheme Loafie \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  test \
  -only-testing:LoafieTests
```

UI-Tests liegen im Target `LoafieUITests` und können über Xcode oder das aktive Test-Plan ausgeführt werden.

## Projektstruktur

```text
Loafie/
├── Design/       Designsystem und Markenfarben
├── Models/       SwiftData-Modelle und Domänen-Enums
├── Services/     Timer, Planung, Mitteilungen, Sessions und WatchConnectivity
├── Shared/       Zwischen iOS-App und Watch geteilte Typen
└── Views/        SwiftUI-Oberflächen nach Funktionsbereich

LoafieLiveActivity/       Live Activity und Dynamic Island
LoafieWatch Extension/    Apple-Watch-Oberfläche und WatchConnectivity
LoafieTests/              Unit-Tests
LoafieUITests/            UI-Tests
docs/                     Spezifikation, Designentscheidungen und Übersetzungshilfen
```

## Architektur

Loafie verwendet SwiftUI für die Oberfläche und SwiftData für die lokale Speicherung. Die zentrale Datenstruktur besteht aus wiederverwendbaren `BakePlan`-Definitionen und daraus erzeugten `BakeSession`-Momentaufnahmen. Timer- und Planungslogik liegt in wiederverwendbaren Services, damit iOS-App, Live Activity und Apple Watch denselben Sitzungszustand verwenden.

Lokalisierte Strings werden in den String Catalogs `Loafie/Localizable.xcstrings` und `LoafieLiveActivity/Localizable.xcstrings` gepflegt. Das visuelle Grundsystem befindet sich in `Loafie/Design/DesignSystem.swift`.

## Weiterführende Dokumentation

- [Designentscheidungen](docs/DesignDecisions.md)
- [App-Spezifikation](docs/sauerteig-timer-app-spezifikation-v1.1.md)
- [Übersetzungshinweise](docs/TranslationPrompt.md)
