import AppKit
import WalkFlowCore

final class HUDWindowController: NSWindowController, NSWindowDelegate, HUDPresenting {
    private static let panelSize = NSSize(width: 160, height: 110)
    private let hudView = HUDView(frame: NSRect(x: 0, y: 0, width: 160, height: 110))
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hudView

        super.init(window: panel)
        panel.delegate = self
        restorePosition()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        window?.orderFrontRegardless()
    }

    func update(_ presentation: HUDPresentation) {
        hudView.update(presentation)
    }

    static func fallbackOrigin(visibleFrame: NSRect, panelSize: NSSize) -> NSPoint {
        NSPoint(x: visibleFrame.maxX - panelSize.width - 20, y: visibleFrame.maxY - panelSize.height - 20)
    }

    static func restoredOrigin(saved: NSPoint?, visibleFrames: [NSRect], panelSize: NSSize) -> NSPoint {
        if let saved {
            let candidate = NSRect(origin: saved, size: panelSize)
            if visibleFrames.contains(where: { $0.contains(candidate) }) {
                return saved
            }
        }

        let fallbackFrame = visibleFrames.first ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return fallbackOrigin(visibleFrame: fallbackFrame, panelSize: panelSize)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        var settings = settingsStore.load()
        settings.hud.savedOriginX = window.frame.origin.x
        settings.hud.savedOriginY = window.frame.origin.y
        settingsStore.save(settings)
    }

    private func restorePosition() {
        guard let window else { return }
        let settings = settingsStore.load()
        let saved = settings.hud.savedOriginX.flatMap { x in
            settings.hud.savedOriginY.map { y in NSPoint(x: x, y: y) }
        }
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        window.setFrameOrigin(Self.restoredOrigin(saved: saved, visibleFrames: visibleFrames, panelSize: Self.panelSize))
    }
}
