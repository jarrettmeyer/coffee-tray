# Coffee Tray

A tiny macOS menu bar app for keeping your Mac awake. It's a friendly front end for the built-in `caffeinate` command.

Click the ☕ icon in the menu bar to turn caffeinate on or off, choose which kinds of sleep to prevent, and optionally set a time to stop.

## Features

- One-click toggle from the menu bar; the icon shows whether caffeinate is active
- Choose what to prevent: display sleep (`-d`), idle sleep (`-i`), system sleep (`-s`), and user-idle assertion (`-u`)
- Optional "until" time, restored correctly if the app is relaunched
- Reflects any `caffeinate` already running, including ones started from the terminal
- Optional launch at login
- Stops all `caffeinate` processes on quit, so nothing is left behind

## Requirements

- macOS 13 or later
- Swift 5.9+ toolchain (Xcode or Command Line Tools) to build from source

## Build and run

There is no Xcode project; the app is built with Swift Package Manager and assembled into a bundle by a script.

```bash
./scripts/build.sh
open "Coffee Tray.app"
```

The bundle is ad-hoc code signed, so it runs locally without a developer certificate.

## Project layout

- `Sources/CoffeeTray/`: app source (AppKit status item + SwiftUI popover)
- `Resources/Info.plist`: bundle metadata (runs as a menu bar agent with no Dock icon)
- `scripts/build.sh`: builds and assembles `Coffee Tray.app`
- `scripts/make-icon.swift`: generates the app icon

## License

[MIT](LICENSE)
