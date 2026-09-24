import SwiftUI

/// SwiftUI's `State` property wrapper under another name.
///
/// In the macOS 27 SDK, `@State` resolves to a new `State` macro whose compiler
/// plugin ships with Xcode.app but not with the Command Line Tools, so `@State`
/// fails to build here. Referring to the property wrapper through a typealias
/// sidesteps the macro. Once the tools include the plugin, swap back to `@State`.
typealias ViewState<Value> = SwiftUI.State<Value>
