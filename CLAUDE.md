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

## Git Workflow Rules

These rules apply to all Git work in this repository. A human exception applies only where a rule explicitly allows one. Repository settings and branch protections still apply.

### Attribution

- Do not add Claude credit or attribution to commits or pull requests. This includes `Co-Authored-By: Claude` (or any variant), other Claude co-author trailers, and Claude credit in commit messages, PR titles, or PR descriptions.

### Branches, pushes, and pull requests

- Create a new branch for every codebase change before making the change, unless a human explicitly instructs you to use another branch or workflow. If currently on `main`, create and switch to a new branch first.
- You may push to feature branches whenever needed without asking for approval.
- Obtain explicit human approval before pushing directly to `main` or merging any branch into `main`. Permission to work on a change or open a PR does not itself approve either action.
- Use a pull request as the default path into `main`. Do not merge a branch directly into `main` unless a human explicitly requests that workflow.
- Merge pull requests into `main` with a merge commit. Use another merge method only when a human explicitly directs it or GitHub repository constraints require it.

### Commit messages

- Follow the repository's established commit message naming convention. Check meaningful recent commits; do not treat a generic bootstrap message such as `Initial commit` as a convention.
- If no convention is established, start each subject with a capitalized, descriptive prefix and a colon, then describe the specific change with appropriate capitalization and enough detail to understand it. Examples:
  - `Add: Fade-in CSS animation to hero block`
  - `Chore: Migrate dependency management from npm to pnpm`
  - `Remove: Unused form component`
  - `Docs: Update README to include CI workflow`

### Conflicts with main

- Never merge a branch that conflicts with `main`. Explain the conflict to the human, propose a resolution, and wait for instructions before resolving it or attempting the merge. Approval to merge is still required after the conflict is resolved.
