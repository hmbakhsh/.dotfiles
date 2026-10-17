// Invisible app that minimize.sh activates after parking the last window on a
// workspace. Something other than the parked app has to be frontmost, or a
// Dock click / Raycast launch of that app is a no-op; and it can't be Finder,
// because Finder in front counts as "the desktop" and makes macOS show the
// auto-hidden menu bar.
//
// macOS won't make a windowless app frontmost, so it keeps a transparent 1x1
// borderless window. AeroSpace only manages standard windows, so it ignores it.
import AppKit

final class SinkWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

final class Delegate: NSObject, NSApplicationDelegate {
    let window = SinkWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
        styleMask: .borderless, backing: .buffered, defer: false)

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        take()
    }

    // Drop the Dock icon once another app has taken focus. (Quitting here
    // instead breaks AeroSpace picking up the newly focused window.)
    func applicationDidResignActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    // macOS won't activate an accessory (no Dock icon) app, so be a regular
    // app for the moment it holds focus.
    private func take() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
