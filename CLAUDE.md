# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NotchX is a macOS app (Swift/SwiftUI) that transforms the MacBook notch into a dynamic control center with music playback, calendar, file shelf with AirDrop, system HUD replacement, battery status, and webcam mirror.

**Requirements:** macOS 14+, Xcode 16+, Apple Silicon or Intel

## Build & Run

```bash
# Open in Xcode
open NotchX.xcodeproj

# Build and run from terminal
xcodebuild -project NotchX.xcodeproj -scheme NotchX -configuration Debug build

# Build, then launch the app
./run.sh
```

Build via Xcode: `Cmd+R`. There are no test targets in this project.

**Two build targets:**
- **NotchX** — main application
- **NotchXXPCHelper** — privileged helper for accessibility/media key interception

## Architecture

### Pattern: MVVM + Coordinator

- **`NotchXViewCoordinator.shared`** — central singleton managing view state and navigation
- **`NotchXViewModel`** — per-notch state (open/closed, sizing, screen UUID binding)
- **Domain managers** (all singletons under `managers/`): `MusicManager`, `CalendarManager`, `WebcamManager`, `BatteryActivityManager`, `BrightnessManager`, `VolumeManager`, `NotchSpaceManager`
- State flows through `ObservableObject` + Combine publishers; preferences stored via `Defaults` framework (200+ keys in `models/Constants.swift`)

### View Hierarchy

```
NotchXApp (Scene) + AppDelegate
├── MenuBarExtra (settings access)
└── NotchXSkyLightWindow (per-display)
    └── ContentView
        ├── Closed state → music cover art + marquee text
        └── Open state → TabSelectionView → NotchHomeView / Shelf
```

`ContentView.swift` is the root view (~850 lines) orchestrating open/closed notch states.

### Music Playback (MediaControllers/)

Abstract `MediaControllerProtocol` with four implementations:
- `NowPlayingController` — system Now Playing framework (handles macOS 15.4+ deprecation via mediaremote-adapter submodule)
- `AppleMusicController` — AppleScript-based
- `SpotifyController` — Spotify Web API
- `YouTubeMusicController` — custom networking (multi-file under YouTube Music Controller/)

`MusicManager` coordinates the active controller and exposes unified playback state.

### Shelf System (components/Shelf/)

Three-tier architecture: Models → Services → Views. Handles drag-drop file acceptance, QuickLook previews, AirDrop/QuickShare integration, persistent file metadata storage.

### HUD Replacement

`MediaKeyInterceptor` intercepts volume/brightness/backlight keys via `NotchXXPCHelper` (XPC). Shows inline indicators in the notch instead of macOS system HUD. Requires accessibility authorization.

### Key Enums (enums/generic.swift)

`NotchState` (.closed/.open), `NotchViews` (.home/.shelf), `ContentType`, `SettingsEnum` (8 settings sections), `Style` (.notch/.floating)

## Branch & Contribution Workflow

- **Main branch:** `NotchX` (used for PRs)
- **Development branch:** `dev` — all code contributions target `dev`
- **Feature branches:** `feature/{name}` format
- Translations handled via Crowdin (auto-syncs with `dev`)

## Key Dependencies (Swift Package Manager)

LaunchAtLogin-Modern, Sparkle (updates), KeyboardShortcuts, Defaults (UserDefaults wrapper), Pow (animations), swiftui-introspect, SkyLightWindow (lock screen overlay), lottie-spm, AsyncXPCConnection, MacroVisionKit

## Notable Conventions

- Multi-display support uses screen UUIDs (see `NSScreen+UUID.swift`), not display names
- `NotchXSkyLightWindow` enables rendering on the lock screen
- `DragDetector` monitors system-wide drag events to auto-open the notch for shelf drops
- Entitlements include sandbox exceptions for camera, calendar, file access, network, and Apple Events (Spotify/Apple Music automation)
