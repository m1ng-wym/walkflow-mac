import AppKit
import WalkFlowCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appController: AppController
    private var mainWindowController: MainWindowController?
    private var hudWindowController: HUDWindowController?
    private var menuBarController: MenuBarController?
    private var applicationMenuController: ApplicationMenuController?

    override convenience init() {
        self.init(appController: AppController())
    }

    init(
        appController: AppController,
        mainWindowController: MainWindowController? = nil,
        hudWindowController: HUDWindowController? = nil
    ) {
        self.appController = appController
        self.mainWindowController = mainWindowController
        self.hudWindowController = hudWindowController
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let main = mainWindowController ?? MainWindowController(appController: appController)
        mainWindowController = main
        showMainWindow(activate: true)

        let hud = hudWindowController ?? HUDWindowController(settingsStore: SettingsStore())
        hud.show()
        hudWindowController = hud
        appController.hudPresenter = hud

        let applicationMenu = ApplicationMenuController(mainWindowController: main)
        applicationMenu.install()
        applicationMenuController = applicationMenu

        menuBarController = MenuBarController(appController: appController, mainWindowController: main, hudWindowController: hud)

        appController.refreshPermissions()
        appController.prepareCameraAuthorizationAndStartRecognition()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard mainWindowController?.window?.isVisible != true else {
            return true
        }

        showMainWindow(activate: false)
        return false
    }

    private func showMainWindow(activate: Bool) {
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        if activate {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
