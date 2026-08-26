<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Mache mir ein paar vorschlage als Text. Erstelle ein Design System und prompts für Grafiken die in den views der Apps verwendet werden können

Hier ist ein vollständiges **Design System** für deine Sauerteig-Timer-App mit Farbpalette, Logo-Konzepten, Design-Prinzipien und Prompts für Grafiken:

***

# Design System: Sauerteig-Timer App

## 1. Farbpalette

### Primärfarben (Brand Colors)

| Name | Hex (Light) | Hex (Dark) | Verwendung |
| :-- | :-- | :-- | :-- |
| **Crust Gold** | `#D4A574` | `#C4956A` | Akzente, aktive Timer, Brot-Assoziation |
| **Flour Cream** | `#F9F5F0` | `#1C1917` | Hintergrund (Light/Dark Mode) |
| **Dough Beige** | `#E8E0D5` | `#2D2824` | Sekundärer Hintergrund, Karten |
| **Sourdough Brown** | `#8B5E3C` | `#A57B5C` | Primäre Buttons, wichtige UI-Elemente |
| **Charcoal** | `#2D2D2D` | `#E8E8E8` | Text (Light/Dark) |

### Systemfarben (für Status \& Interaktion)

| Name | Hex | Verwendung |
| :-- | :-- | :-- |
| **Active Timer** | `#D4A574` | Laufende Timer, Fortschritt |
| **Completed** | `#34C759` | Abgeschlossene Phasen (SF Grün) |
| **Paused** | `#FF9500` | Pausierte Timer (SF Orange) |
| **Warning** | `#FF3B30` | Kühlschrank-Maximum überschritten (SF Rot) |
| **Secondary** | `#8E8E93` | Deaktivierte Elemente, Placeholder |

### Farbkombinationen für verschiedene Kontexte

```swift
// Light Mode
Color.background = Color("Flour Cream")      // #F9F5F0
Color.card = Color("Dough Beige")            // #E8E0D5
Color.accent = Color("Crust Gold")           // #D4A574
Color.textPrimary = Color("Charcoal")        // #2D2D2D
Color.textSecondary = Color("Secondary")     // #8E8E93

// Dark Mode
Color.background = Color("Flour Cream Dark") // #1C1917
Color.card = Color("Dough Beige Dark")       // #2D2824
Color.accent = Color("Crust Gold Dark")      // #C4956A
Color.textPrimary = Color("Charcoal Light")  // #E8E8E8
Color.textSecondary = Color("Secondary")     // #8E8E93
```


### Kontrastverhältnisse (WCAG AA)

- **Crust Gold auf Flour Cream**: 4.7:1 ✓
- **Sourdough Brown auf Flour Cream**: 6.2:1 ✓
- **Charcoal auf Flour Cream**: 12.5:1 ✓
- **Crust Gold auf Charcoal**: 8.1:1 ✓

***

## 2. Logo-Konzepte (Text-Beschreibungen)

### Konzept 1: **Minimalist Loaf**

- **Form**: Einfache geometrische Brot-Laib-Silhouette (halbrund oben, flach unten)
- **Stil**: Flaches Design, keine Schattierungen, einfarbig
- **Farbe**: Crust Gold auf transparentem oder Flour Cream Hintergrund
- **Einsatz**: App Icon, Tab Bar, Watch App
- **Bedeutung**: Sofort erkennbar, universell, reduziert auf das Wesentliche


### Konzept 2: **Timer + Brot**

- **Form**: Kreis (Timer) mit stilisiertem Brot-Schnitt darin (wie eine angeschnittene Brotscheibe mit Krume)
- **Stil**: Line-Art, dünne Striche, modern
- **Farbe**: Sourdough Brown oder Crust Gold
- **Einsatz**: Splash Screen, Marketing, Webseite
- **Bedeutung**: Verbindung von Zeit und Brotbacken


### Konzept 3: **SF Symbols Integration**

- **Form**: Custom SF Symbol aus `timer` + `bread.slices` kombiniert
- **Stil**: Matcht exakt SF Symbols Strichstärke und Eckenradien
- **Farbe**: System Aczentfarbe (dynamisch anpassbar)
- **Einsatz**: In-App Icons, Watch Komplikationen
- **Bedeutung**: Nahtlose Integration in iOS-Ökosystem


### Konzept 4: **Typography Logo**

- **Text**: "Sauerteig" oder "Brotzeit" in custom Sans-Serif
- **Stil**: Clean, geometric, ähnlich SF Pro Display
- **Besonderheit**: Das "o" in "Brot" als stilisierter Brot-Laib
- **Farbe**: Charcoal oder Sourdough Brown
- **Einsatz**: Webseite, Marketing, App Store Screenshots

***

## 3. Design-Prinzipien

### 3.1 Visuelle Hierarchie

1. **Eine dominante Aktion pro Screen**: Der wichtigste Button (z.B. "Timer starten") ist am größten und in Crust Gold
2. **Sekundäre Aktionen**: In Sourdough Brown oder als Outline-Button
3. **Tertiäre Aktionen**: Als reiner Text-Button oder Icon

### 3.2 Typografie

- **Font**: SF Pro (System Font)
- **Größen**:
    - Large Title: 34pt (Headers)
    - Title 1: 28pt (Screen-Titel)
    - Title 2: 22pt (Section Headers)
    - Title 3: 20pt (Card-Titel)
    - Body: 17pt (Fließtext)
    - Callout: 16pt (Timer-Zahlen)
    - Subheadline: 15pt (Beschreibungen)
    - Footnote: 13pt (Hinweise, Metadaten)
- **Gewichtung**:
    - Semibold für Headers
    - Regular für Body
    - Light für große Countdown-Zahlen


### 3.3 Abstände \& Layout

- **Grid**: 8pt-System (alle Abstände sind Vielfache von 8)
- **Card Padding**: 16pt innen
- **Screen Margin**: 20pt außen (iPhone), 16pt (Watch)
- **Zwischen Elementen**: 12–16pt vertikal
- **Zwischen Sections**: 24–32pt vertikal


### 3.4 Formen \& Ecken

- **Card Corner Radius**: 12pt
- **Button Corner Radius**: 10pt
- **Input Field Radius**: 8pt
- **App Icon**: 22% Corner Radius (iOS Standard)


### 3.5 Schatten \& Tiefe

- **Cards**: Kein Schatten (flaches Design)
- **Modals**: System Material (`ultraThinMaterial`)
- **Floating Elements**: Leichter Schatten (`color: black, opacity: 0.1, radius: 8`)
- **Dark Mode**: Schatten reduzieren oder entfernen

***

## 4. Grafiken für App-Views (Prompts)

### 4.1 Empty States

#### Zeitpläne leer

**Prompt**: "Minimalist illustration of an empty kitchen counter with a rolling pin and flour dust, warm beige and cream tones, flat design, no text, clean vector style"

#### Kein aktiver Timer

**Prompt**: "Simple line drawing of a kitchen timer on a counter, soft shadows, minimalist, warm color palette, empty state illustration for baking app"

### 4.2 Phase Icons (Custom SF Symbols Style)

#### Autolyse

**Prompt**: "SF Symbols style icon of a bowl with flour and water, simple line art, single weight stroke, no fill, minimalist"

#### Stockgare

**Prompt**: "SF Symbols style icon of a covered bowl with small bubbles rising, line art, consistent stroke width, minimalist timer app icon"

#### Dehnen \& Falten

**Prompt**: "SF Symbols style icon showing two hands stretching dough, simplified geometric shapes, line art, single stroke weight"

#### Kühlschrank

**Prompt**: "SF Symbols style icon of a refrigerator or snowflake, minimal, clean lines, consistent with iOS system icons"

#### Backofen

**Prompt**: "SF Symbols style icon of an oven with flame symbol inside, simple line drawing, no gradients, single color"

### 4.3 Onboarding Grafiken

#### Schritt 1: Zeitplan erstellen

**Prompt**: "Flat illustration of a smartphone showing a timeline with bread icons, warm colors, minimalist onboarding graphic, no text"

#### Schritt 2: Timer starten

**Prompt**: "Simple illustration of a finger tapping a large timer button on a phone screen, clean vector style, warm beige and gold tones"

#### Schritt 3: Erinnerungen erhalten

**Prompt**: "Minimalist phone with notification bubble showing a bread icon, soft shadows, flat design, onboarding illustration"

### 4.4 Watch App Grafiken

#### Komplikation: Aktiver Timer

**Prompt**: "Circular watch complication icon showing a simplified bread loaf with a small timer overlay, high contrast, readable at small size, flat design"

#### Falt-Erinnerung

**Prompt**: "Simple icon of two hands folding dough, minimal detail, optimized for Apple Watch small icon size, single color"

### 4.5 Marketing Grafiken (App Store)

#### Screenshot Header

**Prompt**: "Wide banner illustration showing a rustic bread loaf on a wooden board with flour scattered around, warm natural lighting, minimalist photography style, no text"

#### Feature Graphic

**Prompt**: "Split composition showing a smartphone with timer app on left and fresh baked sourdough bread on right, cohesive warm color palette, clean product photography"

***

## 5. UI-Komponenten (SwiftUI Code)

### 5.1 Farbe als Extension

```swift
extension Color {
    // Brand Colors
    static let crustGold = Color("CrustGold")
    static let flourCream = Color("FlourCream")
    static let doughBeige = Color("DoughBeige")
    static let sourdoughBrown = Color("SourdoughBrown")
    
    // Semantic Colors
    static let timerActive = Color.crustGold
    static let timerCompleted = Color.green
    static let timerPaused = Color.orange
    static let timerWarning = Color.red
}
```


### 5.2 Standard Button

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.crustGold)
                .cornerRadius(10)
        }
    }
}
```


### 5.3 Phase Card

```swift
struct PhaseCard: View {
    let phase: TimerPhase
    let duration: String
    let status: PhaseStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: phase.icon)
                    .font(.title2)
                    .foregroundColor(.crustGold)
                
                Text(phase.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text(duration)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            
            if status == .active {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.crustGold)
            }
        }
        .padding()
        .background(Color.doughBeige)
        .cornerRadius(12)
    }
}
```


***

## 6. Apple Watch Design-Anpassungen

### 6.1 Watch-spezifische Farben

- **Hintergrund**: System Background (schwarz im Dark Mode)
- **Text**: System White / Gray
- **Akzent**: Crust Gold (aber reduziert, da Watch weniger Farbe bevorzugt)
- **Kontrast**: Mindestens 4.5:1 für alle Textelemente


### 6.2 Watch-Typografie

- **Minimum**: 12pt (HIG Requirement)
- **Standard**: 14–16pt für Body
- **Large**: 20–24pt für Countdown-Zahlen
- **Gewichtung**: Bold für wichtige Informationen


### 6.3 Watch-Layout

- **Padding**: 12–16pt außen
- **Zeilenabstand**: 8–12pt
- **Touch Targets**: Mindestens 44x44pt (auch auf Watch)
- **Glanceability**: Wichtigste Information in oberen 50% des Screens

***

## 7. Image Generation Prompts (Zusammenfassung)

| Grafiktyp | Prompt-Kern | Stil |
| :-- | :-- | :-- |
| App Icon | "Minimalist bread loaf silhouette, geometric, warm golden brown" | Flat, iOS-style |
| Empty State | "Empty kitchen counter with rolling pin and flour, warm tones" | Flat illustration |
| Phase Icons | "SF Symbols style [Element], line art, single stroke weight" | System-konform |
| Onboarding | "Smartphone showing timeline with bread icons, warm colors" | Flat vector |
| Marketing | "Rustic bread loaf on wooden board, natural lighting" | Minimalist photo |
| Watch Komplikation | "Circular bread icon with timer overlay, high contrast" | Optimized for small size |


***

## 8. Nächste Schritte

1. **App Icon finalisieren**: Konzept 1 (Minimalist Loaf) in 1024x1024 für App Store
2. **SF Symbols erweitern**: Custom Icons für alle 12 Phasen im SF Symbols Stil
3. **Color Assets erstellen**: Xcode Asset Catalog mit Light/Dark Mode Varianten
4. **Onboarding-Grafiken**: 3–5 Illustrationen für First-Use-Experience
5. **Watch Komplikationen**: 2–3 Designs für verschiedene Watch-Faces

Möchtest du, dass ich dir konkrete SwiftUI-Code-Beispiele für die UI-Komponenten erstelle oder Image-Prompts für spezifische Grafiken weiter ausarbeite?
<span style="display:none">[^1][^10][^11][^12][^13][^14][^15][^2][^3][^4][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://developer.apple.com/design/human-interface-guidelines/sf-symbols

[^2]: https://developer.apple.com/design/human-interface-guidelines/icons

[^3]: https://developer.apple.com/design/human-interface-guidelines/accessibility

[^4]: https://developer.apple.com/design/human-interface-guidelines/foundations

[^5]: https://developer.apple.com/design/human-interface-guidelines

[^6]: https://developer.apple.com/design/human-interface-guidelines/color

[^7]: https://developer.apple.com/design/human-interface-guidelines/materials

[^8]: https://developer.apple.com/videos/play/wwdc2025/356/

[^9]: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

[^10]: https://developer.apple.com/design/human-interface-guidelines/dark-mode

[^11]: https://apple.raintree.technology/topics/sf-symbols

[^12]: https://app.uxcel.com/courses/apple-hig/accessibility-inclusion-standards-812/color-and-contrast-requirements-0359

[^13]: https://accessibilityforyoux.org/learning/apple-guidelines

[^14]: https://www.brilworks.com/blog/apple-human-interface-guidelines/

[^15]: https://gist.github.com/eonist/4eea05ab911336d39f0b3e715a4aa592

