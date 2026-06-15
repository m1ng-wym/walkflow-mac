import AppKit

final class MenuBarController: NSObject, NSMenuDelegate {
    static let requiredMenuTitles = ["Enable", "Pause", "Show HUD", "Open Window", "Settings", "Quit"]

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private weak var appController: AppController?
    private weak var mainWindowController: MainWindowController?
    private weak var hudWindowController: HUDWindowController?
    private weak var enableItem: NSMenuItem?
    private weak var pauseItem: NSMenuItem?

    var installedMenuTitles: [String] {
        statusItem.menu?.items.filter { $0.isSeparatorItem == false }.map(\.title) ?? []
    }

    init(appController: AppController, mainWindowController: MainWindowController, hudWindowController: HUDWindowController) {
        self.appController = appController
        self.mainWindowController = mainWindowController
        self.hudWindowController = hudWindowController
        super.init()
        configure()
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configure() {
        statusItem.button?.title = "✋"

        let menu = NSMenu()
        let enable = NSMenuItem(title: Self.requiredMenuTitles[0], action: #selector(enable), keyEquivalent: "")
        let pause = NSMenuItem(title: Self.requiredMenuTitles[1], action: #selector(pause), keyEquivalent: "")
        enableItem = enable
        pauseItem = pause

        menu.addItem(enable)
        menu.addItem(pause)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: Self.requiredMenuTitles[2], action: #selector(showHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: Self.requiredMenuTitles[3], action: #selector(openWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: Self.requiredMenuTitles[4], action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: Self.requiredMenuTitles[5], action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }
        menu.delegate = self
        statusItem.menu = menu
        syncMenuState()
    }

    func menuWillOpen(_ menu: NSMenu) {
        syncMenuState()
    }

    @objc private func enable() {
        guard let appController else { return }
        appController.setEnabled(appController.state.isEnabled == false)
        syncMenuState()
    }

    @objc private func pause() {
        guard let appController else { return }
        appController.setPaused(appController.state.isPaused == false)
        syncMenuState()
    }

    @objc private func showHUD() {
        hudWindowController?.show()
    }

    @objc private func openWindow() {
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        openWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func syncMenuState() {
        enableItem?.state = appController?.state.isEnabled == true ? .on : .off
        pauseItem?.state = appController?.state.isPaused == true ? .on : .off
    }
}
