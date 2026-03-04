# NotchX — Figma-to-Code Design System Rules

> Rules for translating Figma designs into NotchX code via the Model Context Protocol.

---

## 1. Token Definitions

### Colors

**No centralized color token system.** Colors are handled via:

- **Accent color** — dynamic, user-configurable:
  ```swift
  // extensions/Color+AccentColor.swift
  Color.effectiveAccent          // User's custom or system accent color
  Color.effectiveAccentBackground // 25% opacity variant for backgrounds
  NSColor.effectiveAccent
  NSColor.effectiveAccentBackground
  ```

- **Notch background** — always `Color.black`

- **Semantic SwiftUI colors** used throughout:
  - `.primary`, `.secondary`, `.tertiary`
  - `.white`, `.gray`, `.red`, `.green`, `.yellow`
  - `Color(nsColor: .secondarySystemFill)` for badges/backgrounds
  - `.separator` for dividers

- **Common inline opacity patterns:**
  ```swift
  .white.opacity(0.1)   // borders, strokes
  .white.opacity(0.04)  // subtle button borders
  .gray.opacity(0.2)    // hover states
  .gray.opacity(0.3)    // track fills
  ```

- **Battery status colors:** `.red` (≤20%), `.green` (charging/full), `.yellow` (low power mode), `.white` (default)

- **AccentColor asset** in `Assets.xcassets/AccentColor.colorset/` — inherits system accent (no hardcoded value)

**Rule:** When translating Figma colors, map to `Color.effectiveAccent` for brand/accent, SwiftUI semantic colors for standard UI, and inline `.opacity()` variants for subtle states. Do NOT create new color constants.

### Spacing

- **One global constant:** `let spacing: CGFloat = 16` in `models/Constants.swift` (rarely used)
- **All other spacing is inline.** Common values: `4, 5, 6, 8, 10, 12, 14, 15, 16, 24`

**Rule:** Use inline `CGFloat` literals matching existing patterns. Do not create spacing tokens.

### Typography

- **No custom font system.** Uses SwiftUI's semantic text styles:
  ```swift
  .font(.largeTitle)                              // Main headings
  .font(.title) / .font(.title2)                  // Section titles
  .font(.headline)                                // Section headers
  .font(.subheadline)                             // Secondary text
  .font(.caption) / .font(.caption2)              // Labels, footnotes
  .font(.system(size: 12, weight: .medium))        // Specific sizing
  .font(.system(.largeTitle, design: .rounded))     // Design variants
  ```

- **Teleprompter exception** — has its own font token enums in `Features/Teleprompter/TeleprompterEnums.swift` (xs=14pt, sm=16pt, lg=20pt, xl=24pt; sans/serif/mono/dyslexia families)

**Rule:** Map Figma text styles to the closest SwiftUI semantic font. Use `.system(size:weight:)` only when exact sizing is critical.

### Corner Radii

| Element | Radius |
|---|---|
| Notch shape (closed) | `12pt top / 14pt bottom` |
| Notch shape (open) | `29pt top / 44pt bottom` |
| Album art (open) | `26pt` |
| Album art (closed) | `4pt` |
| Shelf items / file tiles | `12pt` |
| Settings icon tiles | `6pt` |
| Buttons (bouncing style) | `10pt` (scaling on) / `4pt` (off) |
| Shelf drop zone | `16pt` |

**Rule:** Use the established radius values above. `Defaults[.cornerRadiusScaling]` toggles between rounded/squared modes.

---

## 2. Component Library

All reusable UI components live under `NotchX/components/`.

### Core Components

| Component | File | Usage |
|---|---|---|
| `HoverButton` | `components/HoverButton.swift` | Primary icon button — SF Symbol + hover Capsule fill |
| `TabButton` | `components/Tabs/TabButton.swift` | Tab bar icon button with SF Symbol |
| `TabSelectionView` | `components/Tabs/TabSelectionView.swift` | Tab bar with `matchedGeometryEffect` capsule indicator |
| `NotchShape` | `components/Notch/NotchShape.swift` | Custom `Shape` for the notch silhouette (animatable radii) |
| `NotchXHeader` | `components/Notch/NotchXHeader.swift` | Top bar: tabs + battery + settings/camera buttons |
| `MarqueeText` | `components/Live activities/MarqueeTextView.swift` | Auto-scrolling text with configurable font, color, pause |
| `EmptyStateView` | `components/EmptyState.swift` | Animated face + gray message text |
| `MinimalFaceFeatures` | `components/AnimatedFace.swift` | Pixelated blinking face mascot |
| `BatteryView` | `components/Live activities/NotchXBattery.swift` | Battery icon with color-coded fill |
| `ProgressIndicator` | `components/ProgressIndicator.swift` | Circular or text progress display |
| `DraggableProgressBar` | `components/Live activities/SystemEventIndicatorModifier.swift` | Capsule track + fill, draggable |
| `CustomSlider` | `components/Notch/NotchHomeView.swift` | Rectangle track + fill, grows on drag |
| `ComingSoonPlaceholder` | `components/Settings/ComingSoonPlaceholder.swift` | Icon + title + description + "Coming Soon" badge |
| `SettingsSidebarLabel` | `components/Settings/SettingsSidebarLabel.swift` | Colored 24x24 icon tile + title + optional "Soon" badge |
| `AudioSpectrumView` | `components/Music/MusicVisualizer.swift` | 4 animated white bars (NSView-backed) |
| `VisualEffectView` | `components/Settings/EditPanelView.swift` | `NSVisualEffectView` wrapper for blur backgrounds |

### Button Styles

```swift
// extensions/Button+Bouncing.swift
BouncingButtonStyle   // Dark bg, white border, 0.9 scale on press, spring animation
// Usage: .bouncingStyle(vm: viewModel)

// components/Live activities/NotchXBattery.swift
ScaleButtonStyle      // 0.95 scale on press, easeInOut
```

### Shelf Components (components/Shelf/)

Three-tier architecture: **Models** → **Services** → **Views**

- `ShelfView` — Drop zone with dashed `RoundedRectangle` border (lineWidth: 3, dash: [10])
- `ShelfItemView` — 105pt wide file tile, 56x56 icon, 12pt corner radius

**Rule:** When implementing new components, check `components/` for existing pieces first. Reuse `HoverButton` for icon actions, `BouncingButtonStyle` for media buttons, `VisualEffectView` for blur backgrounds.

---

## 3. Frameworks & Libraries

| Technology | Role |
|---|---|
| **SwiftUI** | Primary UI framework |
| **AppKit (NSKit)** | Window management, `NSVisualEffectView`, `NSFont`, `NSColor`, `NSImage`, `NSView` subclasses |
| **Defaults** (sindresorhus) | Type-safe UserDefaults — all settings/preferences |
| **Pow** (EmergeTools) | Advanced SwiftUI transitions (`.blurReplace`, etc.) |
| **Lottie** (airbnb) | Animation rendering |
| **swiftui-introspect** | Access underlying AppKit controls |
| **KeyboardShortcuts** | Custom keyboard shortcut binding |
| **SkyLightWindow** | Lock-screen overlay rendering |

**Build System:** Xcode 16+ / Swift Package Manager for dependencies

**Rule:** Use SwiftUI as the primary view layer. Fall back to AppKit (`NSViewRepresentable`) only when SwiftUI lacks the capability (e.g., blur effects, custom drawing, audio visualization).

---

## 4. Asset Management

### Assets.xcassets

Location: `NotchX/Assets.xcassets/`

| Asset | Type | Usage |
|---|---|---|
| `AppIcon.appiconset` | PNG (multiple sizes) | App icon |
| `AccentColor.colorset` | Color | System accent |
| `logo` / `logo2` | PNG | Settings About / Welcome screen |
| `marvinbarsal` | SVG | Creator logo (`.blendMode(.overlay)`) |
| `spotlight` | SVG | Welcome screen background glow |
| `sparkle` | SVG | Updater icon |
| `chrome` | PNG (3 sizes) | Browser icon for downloads |
| `bolt` / `plug` | PNG | Battery status icons |
| `Github` | SVG (3 sizes) | GitHub link icon |

### Custom Fonts

- `Features/Teleprompter/Fonts/OpenDyslexic3-Regular.ttf` — registered via `ATSApplicationFontsPath` in Info.plist

**Rule:** Add new image assets to `Assets.xcassets` as imagesets. Reference with `Image("assetName")`. For app-specific icons, prefer SF Symbols.

---

## 5. Icon System

### SF Symbols (Primary)

SF Symbols are used universally. Key patterns:

```swift
// Navigation
Image(systemName: "house.fill")          // Home tab
Image(systemName: "tray.fill")           // Shelf tab
Image(systemName: "text.word.spacing")   // Teleprompter tab
Image(systemName: "gear")                // Settings
Image(systemName: "web.camera.fill")          // Webcam

// Music controls
"play.fill" / "pause.fill"
"backward.fill" / "forward.fill"
"shuffle" / "repeat" / "repeat.1"
"speaker.wave.1" / "speaker.wave.2" / "speaker.wave.3" / "speaker.slash"
"heart" / "heart.fill"

// HUD
"sun.min" / "sun.max"    // Brightness
"light.min" / "light.max" // Backlight
"mic" / "mic.slash"       // Microphone

// Rendering modifiers
.symbolVariant(.fill)
.symbolRenderingMode(.hierarchical)
.contentTransition(.symbolEffect)
.contentTransition(.interpolate)
```

### Custom PNG/SVG Assets

Only used for brand icons (Chrome, GitHub) and app branding (logo, spotlight). See Section 4.

### Dynamic App Icons

```swift
// helpers/AppIcons.swift
AppIcon(for: bundleID) -> Image          // Fetches running app's icon via NSWorkspace
AppIconAsNSImage(for: bundleID) -> NSImage?
```

**Rule:** Always use SF Symbols for UI icons. Only add custom assets for brand logos or when no suitable SF Symbol exists. Use `.fill` variants for selected/active states.

---

## 6. Styling Approach

### Layout Pattern

The notch renders in a custom `NSWindow` (`NotchXSkyLightWindow`) per display. Views adapt based on `NotchState` (.open/.closed).

```swift
// Closed state: compact bar with album art + marquee text
// Open state:   expanded panel with tabs (home/shelf/teleprompter)
```

### Backgrounds

- **Notch panel:** Always `Color.black` with `NotchShape` clip
- **Blur effects:** `VisualEffectView(material:blendingMode:)` wrapper
  - `.hudWindow` for overlays
  - `.underWindowBackground` for panels
- **Settings:** Native `Form` / `NavigationSplitView` (system-styled)

### Hover States

```swift
// HoverButton pattern:
// Default: transparent
// Hover:   Capsule filled with .gray.opacity(0.2)

// BouncingButtonStyle:
// Press:   scaleEffect(0.9) with .spring(response: 0.3, dampingFraction: 0.3)
```

### Animations

```swift
// Primary notch animation (animations/drop.swift):
.spring(.bouncy(duration: 0.4))

// Hover animations:
.smooth(duration: 0.3)

// UI transitions:
.spring(.bouncy(duration: 0.3))    // Empty state
.easeInOut(duration: 0.6)          // Onboarding
.interactiveSpring(response: 0.32, dampingFraction: 0.76)  // Camera expand
```

### View Modifiers & Extensions

```swift
// extensions/ConditionalModifier.swift
.conditionalModifier(condition) { view in ... }

// extensions/ActionBar.swift
.actionBar(padding: 10) { /* toolbar content */ }

// animations/HelloAnimation.swift
.glow(fill:lineWidth:blurRadius:lineCap:)  // Triple-layer glow effect
```

### Responsive / Multi-Display

- Screen UUIDs (`NSScreen+UUID.swift`) identify displays, NOT display names
- Each display gets its own `NotchXSkyLightWindow`
- Notch sizing adapts per `NotchXViewModel` bound to screen UUID

**Rule:** All new views should use SwiftUI modifiers. Use `.conditionalModifier()` for conditional styling. Match existing animation timing. The notch background is always black — design content for dark-on-black contrast.

---

## 7. Project Structure

```
NotchX/
├── ContentView.swift              # Root view (~860 lines) — open/closed notch orchestration
├── NotchXApp.swift                # @main + AppDelegate
│
├── models/
│   ├── Constants.swift            # 200+ Defaults.Keys, global constants
│   └── NotchXViewModel.swift      # Per-notch state (ObservableObject)
│
├── enums/
│   └── generic.swift              # NotchState, NotchViews, SettingsEnum, Style, ContentType
│
├── sizing/
│   └── matters.swift              # Layout dimensions, corner radii, MusicPlayerImageSizes
│
├── extensions/                    # Color, Button, View, NSImage, NSScreen extensions
├── animations/                    # NotchXAnimations, HelloAnimation glow effects
│
├── components/
│   ├── Notch/                     # NotchShape, NotchXHeader, NotchHomeView, windows
│   ├── Tabs/                      # TabButton, TabSelectionView
│   ├── Music/                     # MusicVisualizer, LottieAnimationView
│   ├── Calendar/                  # NotchXCalendar
│   ├── Shelf/                     # Models/ Services/ Views/ ViewModels/
│   ├── Settings/                  # SettingsView, sidebar labels, placeholders
│   ├── Live activities/           # MarqueeText, HUD, Battery, Progress, Downloads
│   ├── Onboarding/                # Welcome, Permissions, MusicSelection, Finish
│   ├── Webcam/                    # WebcamView
│   ├── Tips/                      # TipStore
│   ├── HoverButton.swift          # Primary reusable icon button
│   ├── AnimatedFace.swift         # Blinking face mascot
│   ├── EmptyState.swift           # Empty state with face + message
│   ├── ProgressIndicator.swift    # Circular/text progress
│   └── BottomRoundedRectangle.swift
│
├── Features/
│   └── Teleprompter/              # Self-contained feature module (enums, settings, service, views)
│
├── managers/                      # Domain singletons (Music, Calendar, Webcam, Battery, etc.)
├── MediaControllers/              # Music source adapters (NowPlaying, AppleMusic, Spotify, YouTube)
├── helpers/                       # AppIcons, AudioPlayer, utilities
├── observers/                     # DragDetector, MediaKeyInterceptor
├── menu/                          # StatusBarMenu
├── Assets.xcassets/               # Images, colors, app icon
└── NotchXXPCHelper/               # Privileged XPC helper target
```

### Feature Organization Pattern

New features follow the `Features/` pattern (see Teleprompter):
- Self-contained directory with enums, settings, service layer, manager, and views
- Settings integrated via `Defaults.Keys` in `Constants.swift`
- Tab integration via `NotchViews` enum in `enums/generic.swift`
- Toggle via a `Defaults` boolean key

---

## Figma-to-Code Translation Rules

1. **Colors:** Map Figma fills to `Color.effectiveAccent`, semantic SwiftUI colors, or inline `.opacity()` variants. Never create new color constants.

2. **Typography:** Map to SwiftUI semantic fonts (`.headline`, `.subheadline`, `.caption`). Use `.system(size:weight:)` only when exact sizing matters.

3. **Icons:** Map to SF Symbols. Use `.fill` for active states, `.symbolRenderingMode(.hierarchical)` for depth.

4. **Spacing:** Use inline `CGFloat` values matching common patterns (4, 8, 10, 12, 16, 24).

5. **Components:** Reuse existing components (`HoverButton`, `TabButton`, `MarqueeText`, `BouncingButtonStyle`) before creating new ones.

6. **Layout:** SwiftUI `VStack`/`HStack`/`ZStack`. The notch is always black background. Content must be high-contrast for dark surfaces.

7. **Animations:** Use `.spring(.bouncy(duration: 0.4))` for primary transitions, `.smooth(duration: 0.3)` for hover states.

8. **New features:** Place under `Features/{FeatureName}/` with self-contained architecture. Register in `enums/generic.swift` and `models/Constants.swift`.
