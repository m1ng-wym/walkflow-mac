import AppKit

final class MainWindowController: NSWindowController {
    private let appController: AppController
    private let previewView = CameraPreviewView(frame: .zero)

    init(appController: AppController) {
        self.appController = appController

        let root = NSSplitView()
        root.isVertical = true
        root.dividerStyle = .thin

        let controlPanel = ControlPanelView(appController: appController)
        let preview = PreviewContainerView(previewView: previewView)
        appController.attachPreview(to: previewView)
        root.addArrangedSubview(controlPanel)
        root.addArrangedSubview(preview)
        controlPanel.widthAnchor.constraint(equalToConstant: 220).isActive = true

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WalkFlow-Mac"
        window.contentView = root
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        nil
    }
}
