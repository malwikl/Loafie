# Loafie — Agent Notes

## Project

- Native SwiftUI iOS app for sourdough bake plans and active timers.
- Xcode project: `Loafie.xcodeproj`
- Shared scheme: `Loafie`
- Swift version: 5.0
- Current app version: `1.0` (build `1`)
- Primary app bundle ID: `de.kloeffer.loafies`
- Primary iOS deployment target: iOS `18.0`
- Live Activity deployment target: iOS `16.1`
- Watch targets deployment target: watchOS `10.0`
- iPhone/iPad family: `1,2`; watch family: `4`

## Targets

- `Loafie` — main iOS app; SwiftUI + SwiftData.
- `LoafieTests` — unit tests; bundle ID `de.kloeffer.LoafieTests`.
- `LoafieUITests` — UI tests; bundle ID `de.kloeffer.LoafieUITests`.
- `LoafieLiveActivity` — Live Activity extension; bundle ID `de.kloeffer.loafies.liveactivity`.
- `LoafieWatch` — watchOS app; bundle ID `de.kloeffer.loafies.watchkitapp`.
- `LoafieWatch Extension` — watchOS extension; bundle ID `de.kloeffer.loafies.watchkitapp.watchkitextension`.

## Architecture and behavior

- SwiftUI views are organized under `Loafie/Views/` by feature: Session, Schedules, Planning, Settings, and Shared.
- Domain models are under `Loafie/Models/`; reusable services are under `Loafie/Services/`.
- SwiftData is persisted on disk through a `ModelContainer` configured in `Loafie/LoafieApp.swift`.
- Main SwiftData schema: `BakePlan`, `BakeStepDefinition`, `FoldReminderConfiguration`, `ReminderDefinition`, `BakeSession`, `SessionStep`, `SessionFoldReminder`, and `SessionReminder`.
- App services include notifications, Live Activities, haptics, timer math, bake-plan planning, session storage, and WatchConnectivity.
- Custom deep-link scheme: `loafie://liveactivity/{pause|next|skip}`.
- Shared iOS/watch data type: `Loafie/Shared/WatchSessionSnapshot.swift`.
- Localization uses `Loafie/Localizable.xcstrings`; German source material is in `docs/Loafie_Localizable_de.csv`.
- Design system and brand colors live in `Loafie/Design/DesignSystem.swift` and the named color assets.

## Important project conventions

- Preserve the existing warm sourdough visual language: Flour Cream, Dough Beige, Crust Gold, Sourdough Brown, and Charcoal.
- Prefer the existing design system and shared services over introducing parallel abstractions.
- Keep iOS, Live Activity, and watchOS behavior synchronized when changing session state or timer actions.
- Add or update unit tests in `LoafieTests/` for timer math, schedule planning, persistence, session state, and WatchConnectivity changes.
- Do not discard unrelated working-tree changes. The repository may contain intentional uncommitted UI and target work.

## Verification

- Build the shared `Loafie` scheme in Xcode before handing off changes.
- Run the active test plan, including `LoafieTests` and `LoafieUITests`, when changes affect behavior or UI.
- For UI changes, render an appropriate SwiftUI preview or run the app in an iOS Simulator when available.
- Use the Xcode project rather than assuming a Swift Package Manager layout.

## Installed development tooling

- Codex plugin installed: `Build iOS Apps` from `openai/plugins/plugins/build-ios-apps`.
- Intended uses: SwiftUI refactoring, previews, Xcode builds, iOS Simulator debugging, App Intents, performance checks, and memory investigation.
- Swift-engineering skills installed from `johnrogers/claude-swift-engineering`:
  - `composable-architecture`
  - `foundation-models`
  - `generating-swift-package-docs`
  - `grdb`
  - `haptics`
  - `ios-26-platform`
  - `ios-hig`
  - `localization`
  - `modern-swift`
  - `sqlite-data`
  - `storekit`
  - `swift-diagnostics`
  - `swift-networking`
  - `swift-style`
  - `swift-testing`
  - `swiftui-advanced`
  - `swiftui-patterns`
- Compatibility note: the source repository emphasizes Swift 6.2 and iOS 26+, while Loafie currently uses Swift 5 and iOS 18. Use newer APIs only behind availability checks and preserve the project’s existing SwiftData architecture unless a migration is explicitly requested.
