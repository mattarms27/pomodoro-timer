# Pomodoro Timer

A native macOS Pomodoro timer with a task list, built with SwiftUI and Liquid Glass.
Built with Swift Package Manager and the Xcode Command Line Tools only (no Xcode.app).

## Build & run

- `swift build` — compile (debug)
- `./Scripts/bundle.sh` — build release and assemble `dist/Pomodoro Timer.app`
- `./Scripts/bundle.sh --run` — same, then launch the app

Targets macOS 26+ (Liquid Glass APIs such as `glassEffect`, `GlassEffectContainer`, `.glassProminent`).

## Git workflow

- Create a separate commit for each notable piece of work.
- Every commit message starts with a task-type prefix: `Add:`, `Fix:`, `Remove:`, `Update:`, `Refactor:`, `Chore:`, `Docs:`.
  - Example: `Add: Task list with drag-to-reorder`
- New features and additions go on their own branch (e.g. `feature/<name>`), never directly on `main`.
- Branches are merged into `main` only via pull request, and only after the user says it's okay.
- Committing locally is fine without asking; **pushing to any branch and merging a PR both require the user's explicit approval** each time.
