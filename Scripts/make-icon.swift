#!/usr/bin/env swift
// Renders the app icon with SwiftUI and packs it into Resources/AppIcon.icns.
// Usage: swift Scripts/make-icon.swift
import AppKit
import SwiftUI

struct AppIcon: View {
    private let tomato = Color(red: 1.0, green: 0.40, blue: 0.30)
    private let ember = Color(red: 0.86, green: 0.16, blue: 0.20)

    var body: some View {
        ZStack {
            // macOS icon grid: an 824pt rounded square centered on a 1024pt canvas.
            RoundedRectangle(cornerRadius: 186, style: .continuous)
                .fill(
                    LinearGradient(colors: [tomato, ember], startPoint: .top, endPoint: .bottom)
                )
                .overlay {
                    // Soft top highlight, like light catching glass.
                    RoundedRectangle(cornerRadius: 186, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.35), .clear],
                                center: UnitPoint(x: 0.3, y: 0.1),
                                startRadius: 0,
                                endRadius: 620
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 186, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 4)
                }
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.28), radius: 20, y: 12)

            // Track
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 64)
                .frame(width: 500, height: 500)

            // Remaining time
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(.white, style: StrokeStyle(lineWidth: 64, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 500, height: 500)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 6)

            // Center dot
            Circle()
                .fill(.white)
                .frame(width: 72, height: 72)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
func renderPNG(size: Int, to url: URL) throws {
    let renderer = ImageRenderer(content: AppIcon())
    renderer.scale = CGFloat(size) / 1024
    guard
        let cgImage = renderer.cgImage,
        let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: url)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = FileManager.default.temporaryDirectory.appending(path: "AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try MainActor.assumeIsolated {
        try renderPNG(size: base, to: iconset.appending(path: "icon_\(base)x\(base).png"))
        try renderPNG(size: base * 2, to: iconset.appending(path: "icon_\(base)x\(base)@2x.png"))
    }
}

let output = root.appending(path: "Resources/AppIcon.icns")
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    fatalError("iconutil failed with status \(iconutil.terminationStatus)")
}
print("✓ Wrote \(output.path)")
