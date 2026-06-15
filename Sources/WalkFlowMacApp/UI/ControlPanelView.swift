import AppKit

final class ControlPanelView: NSView {
    private let appController: AppController

    init(appController: AppController) {
        self.appController = appController
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func build() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let permissions = PermissionPanelView(appController: appController)
        let enable = NSButton(checkboxWithTitle: "Enable", target: self, action: #selector(toggleEnable(_:)))
        enable.state = .on
        let pause = NSButton(checkboxWithTitle: "Pause", target: self, action: #selector(togglePause(_:)))

        stack.addArrangedSubview(permissions)
        stack.addArrangedSubview(enable)
        stack.addArrangedSubview(pause)
        stack.addArrangedSubview(NSTextField(labelWithString: "HUD Position: Pinned"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Shortcut: Not Set"))

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        ])
    }

    @objc private func toggleEnable(_ sender: NSButton) {
        appController.setEnabled(sender.state == .on)
    }

    @objc private func togglePause(_ sender: NSButton) {
        appController.setPaused(sender.state == .on)
    }
}
