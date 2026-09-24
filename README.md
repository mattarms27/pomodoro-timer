# Pomodoro Timer

A native macOS Pomodoro timer with a built-in task list, written in SwiftUI with Liquid Glass.

## Features

- **Pomodoro cycle** — Focus, Short Break, and Long Break phases, with a long break after a configurable number of sessions.
- **Task list** — Add tasks, estimate how many Pomodoros each will take, and pick a current task. Each finished focus session is credited to it.
- **Liquid Glass** — Glass controls that morph as the timer starts and stops, a glass session indicator, and a glass task field.
- **Appearance** — Automatic (follows the system), Light, or Dark, set in Settings or from View ▸ Appearance.
- **Menu bar timer** — The countdown in the menu bar, with a popover for quick controls. The timer keeps running after the window is closed.
- **Alerts** — A sound and a notification when each phase ends.
- **Accurate timing** — The countdown works from an end time, so it stays correct through sleep and App Nap.

## Requirements

- macOS 26 or later
- Xcode Command Line Tools (`xcode-select --install`). Xcode.app is **not** required.

## Build & run

```bash
./Scripts/bundle.sh --run
```

This builds a release binary with Swift Package Manager, assembles and ad-hoc signs `dist/Pomodoro Timer.app`, and opens it. Leave off `--run` to build without launching. You can drag the `.app` into `/Applications`.

To regenerate the app icon after editing `Scripts/make-icon.swift`:

```bash
swift Scripts/make-icon.swift
```

## Keyboard shortcuts

| Action | Shortcut |
| --- | --- |
| Start / Pause | ⌘↩ |
| Reset | ⌘R |
| Skip to next phase | ⌥⌘→ |
| Focus / Short Break / Long Break | ⌘1 / ⌘2 / ⌘3 |
| New task | ⌘N |
| Settings | ⌘, |

## Project layout

```
Sources/PomodoroTimer/
  PomodoroTimerApp.swift   App entry point and scenes (window, settings, menu bar)
  Models/                  Timer engine, phases, settings, task store
  Views/                   Timer, controls, task list, settings, menu bar UI
  Support/                 Notifications and the ViewState alias
Resources/                 Info.plist and the app icon
Scripts/                   Bundling and icon generation
```

Tasks are stored in `~/Library/Application Support/PomodoroTimer/tasks.json`. Preferences are stored in `UserDefaults`.
