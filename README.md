# Veil

macOS menu bar app that softly blanks other monitors when fullscreen video is detected.

## Features

- **Auto-detection**: Detects fullscreen video playback on any monitor
- **Soft blank**: Overlays other monitors with a black screen
- **FlipClock**: Optional clock display on blanked monitors
- **Menu bar**: Runs as a lightweight menu bar utility (no Dock icon)

## Install

```bash
brew tap neocode24/tap
brew install --cask veil
```

## How It Works

1. Veil monitors all windows using CoreGraphics APIs
2. When a known video player app enters fullscreen, it identifies the active monitor
3. All other monitors get a black overlay (soft-off)
4. When fullscreen exits, all monitors are restored

### Supported Apps

Safari, Chrome, Firefox, Arc, Edge, VLC, QuickTime, IINA, mpv, Apple TV, Netflix, Disney+, Prime Video, Infuse, Plex, Zoom, FaceTime, and more. Custom apps can be added from the menu bar UI.

## Build from Source

```bash
# Quick build
make setup    # Install XcodeGen + generate project
make build    # Build Release

# Or manually
brew install xcodegen
cd Veil && xcodegen generate
open Veil.xcodeproj
```

## Release

```bash
make package   # Build + zip
make release   # Package + create GitHub release
```

Tag-based releases trigger GitHub Actions CI automatically:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16.0+

## License

[MIT License](LICENSE)
