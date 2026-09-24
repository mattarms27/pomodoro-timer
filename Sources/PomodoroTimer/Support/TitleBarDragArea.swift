import SwiftUI

/// Content drawn up into the title bar strip covers the real title bar, so this
/// restores its behavior in the empty space behind that content: drag to move the
/// window, and double-click to zoom or minimize, per System Settings.
struct TitleBarDragArea: View {
    var body: some View {
        Color.clear
            .contentShape(.rect)
            .gesture(WindowDragGesture())
            .onTapGesture(count: 2) {
                let window = NSApp.keyWindow
                switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
                case "Minimize": window?.miniaturize(nil)
                case "None": break
                default: window?.zoom(nil)
                }
            }
    }
}
