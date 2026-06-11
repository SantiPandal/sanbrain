// Sanbrain: voice-memo menu bar indicator.
// Shows "🔴 m:ss" in the macOS menu bar while a voice memo is recording —
// the Apple-native answer to "is it recording?". Spawned by voice-memo on
// start, killed by it on finish; clicking the item offers stop.
// Compiled by install-voice-memo.sh: swiftc -O -o ~/.local/bin/voice-memo-menubar
// No special permissions needed (NSStatusItem is plain AppKit).

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let started = Date()
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        update()

        let menu = NSMenu()
        let stop = NSMenuItem(title: "⏹ Detener y transcribir", action: #selector(stopRecording), keyEquivalent: "")
        stop.target = self
        menu.addItem(stop)
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func update() {
        let s = Int(Date().timeIntervalSince(started))
        statusItem.button?.title = String(format: "🔴 %d:%02d", s / 60, s % 60)
    }

    @objc func stopRecording() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = [NSString(string: "~/.local/bin/voice-memo").expandingTildeInPath, "finish"]
        try? p.run()
        // finish kills this process; terminate ourselves as fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { NSApp.terminate(nil) }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
