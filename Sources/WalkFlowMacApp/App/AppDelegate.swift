import AppKit
import WalkFlowCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appController = AppController()
    private var mainWindowController: MainWindowController?
    private var hudWindowController: HUDWindowController?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let main = MainWindowController(appController: appController)
        main.showWindow(nil)
        main.window?.makeKeyAndOrderFront(nil)
        mainWindowController = main

        let hud = HUDWindowController(settingsStore: SettingsStore())
        hud.show()
        hudWindowController = hud
        appController.hudPresenter = hud

        menuBarController = MenuBarController(appController: appController, mainWindowController: main, hudWindowController: hud)

        appController.refreshPermissions()
        appController.prepareCameraAuthorizationAndStartRecognition()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
