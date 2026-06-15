import AppKit
import WalkFlowCore

final class LottieStatusIconView: NSView {
    private(set) var currentIcon: HUDIcon = .none

    func show(icon: HUDIcon) {
        currentIcon = icon
        isHidden = icon == .none
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
    }
}
