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

## New to the Pomodoro Technique?

The Pomodoro Technique breaks work into short, focused blocks with regular breaks. Each block is called a *Pomodoro*.

1. **Pick a task.** Add it to the task list and set roughly how many Pomodoros you think it will take by clicking its dots.
2. **Focus for 25 minutes.** Press Start and work only on that task until the timer ends. If something else comes to mind, jot it down as a new task and get back to work.
3. **Take a 5-minute break.** Breaks start on their own. Step away from the screen.
4. **Repeat.** Press Start for the next focus session when you're ready. After every 4 sessions you get a longer 15-minute break.

Some tips:

- Each finished focus session is credited to the current task, so a task can take several Pomodoros. That's what the estimate is for. Finishing over it just shows as, say, `2/1`.
- When you finish a task, tick it off and the next one becomes current.
- Batch tiny tasks (a few quick emails, say) into a single Pomodoro instead of giving each one a full session.
- All durations, and whether breaks and focus sessions start automatically, can be changed in Settings (⌘,).

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
