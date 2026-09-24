# Pomodoro Timer

A native macOS Pomodoro timer with a task list, built with SwiftUI and Liquid Glass.
Built with Swift Package Manager and the Xcode Command Line Tools only (no Xcode.app).

## Build & run

- `swift build` — compile (debug)
- `./Scripts/bundle.sh` — build release and assemble `dist/Pomodoro Timer.app`
- `./Scripts/bundle.sh --run` — same, then launch the app

Targets macOS 26+ (Liquid Glass APIs such as `glassEffect`, `GlassEffectContainer`, `.glassProminent`).

## Code conventions

- Use `@ViewState` instead of `@State` for view-local state. In the macOS 27 SDK `@State` is a macro whose
  plugin ships only with Xcode.app, so it fails to build with the Command Line Tools. `ViewState` is a
  typealias for the `State` property wrapper (see `Support/ViewState.swift`). Avoid other SwiftUI macros
  (`@Entry`, `@Animatable`, `#Preview`) for the same reason. `@Observable` works.
- The package uses `defaultIsolation(MainActor.self)`; everything is main-actor by default.
- To check UI changes, run `./Scripts/bundle.sh --run` and take a window screenshot with `screencapture -l <windowID>`.

## Git workflow

- Create a separate commit for each notable piece of work.
- Every commit message starts with a task-type prefix: `Add:`, `Fix:`, `Remove:`, `Update:`, `Refactor:`, `Chore:`, `Docs:`.
  - Example: `Add: Task list with drag-to-reorder`
- New features and additions go on their own branch (e.g. `feature/<name>`), never directly on `main`.
- Branches are merged into `main` only via pull request, and only after the user says it's okay.
- Committing locally is fine without asking; **pushing to any branch and merging a PR both require the user's explicit approval** each time.
