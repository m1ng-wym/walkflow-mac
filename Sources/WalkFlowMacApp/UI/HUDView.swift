import AppKit
import WalkFlowCore

final class HUDView: NSView {
    private var presentation = HUDPresentation(dot: .green, icon: .none, message: "Standby")
    private let iconView = LottieStatusIconView(frame: NSRect(x: 48, y: 28, width: 64, height: 64))
    private static let arrowHeight: CGFloat = 8

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        addSubview(iconView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(_ presentation: HUDPresentation) {
        self.presentation = presentation
        iconView.show(icon: presentation.icon)
        needsDisplay = true
    }

    static func panelRect(in bounds: NSRect) -> NSRect {
        NSRect(x: bounds.minX + 2, y: bounds.minY + 2, width: bounds.width - 4, height: bounds.height - arrowHeight - 4)
    }

    static func arrowPoints(in bounds: NSRect) -> [NSPoint] {
        let panel = panelRect(in: bounds)
        let midX = bounds.midX
        return [
            NSPoint(x: midX - 8, y: panel.maxY - 1),
            NSPoint(x: midX, y: bounds.maxY - 2),
            NSPoint(x: midX + 8, y: panel.maxY - 1)
        ]
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let panel = NSBezierPath(roundedRect: Self.panelRect(in: bounds), xRadius: 10, yRadius: 10)
        NSColor.windowBackgroundColor.withAlphaComponent(0.92).setFill()
        panel.fill()

        let arrow = NSBezierPath()
        let points = Self.arrowPoints(in: bounds)
        arrow.move(to: points[0])
        arrow.line(to: points[1])
        arrow.line(to: points[2])
        arrow.close()
        NSColor.windowBackgroundColor.withAlphaComponent(0.92).setFill()
        arrow.fill()

        let dotColor: NSColor = presentation.dot == .green ? .systemGreen : .systemRed
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 18, y: bounds.height - 34, width: 10, height: 10)).fill()
    }
}
