import AppKit

final class PermissionPanelView: NSView {
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
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(NSTextField(labelWithString: "Permissions"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Camera"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Accessibility"))
        stack.addArrangedSubview(NSButton(title: "Recheck", target: self, action: #selector(recheck)))

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func recheck() {
        appController.refreshPermissions()
    }
}
