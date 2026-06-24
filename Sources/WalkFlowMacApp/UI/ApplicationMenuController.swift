import AppKit

final class ApplicationMenuController: NSObject {
    private weak var mainWindowController: MainWindowController?

    init(mainWindowController: MainWindowController) {
        self.mainWindowController = mainWindowController
        super.init()
    }

    func install() {
        NSApplication.shared.mainMenu = makeMainMenu()
    }

    @objc func closeMainWindow(_ sender: Any?) {
        mainWindowController?.window?.performClose(sender)
    }

    @objc func minimizeMainWindow(_ sender: Any?) {
        mainWindowController?.window?.performMiniaturize(sender)
    }

    @objc func hideApplication(_ sender: Any?) {
        NSApplication.shared.hide(sender)
    }

    @objc func quitApplication(_ sender: Any?) {
        NSApplication.shared.terminate(sender)
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu(title: "MainMenu")
        addSubmenu(named: "WalkFlow-Mac", submenu: makeApplicationMenu(), to: mainMenu)
        addSubmenu(named: "File", submenu: makeFileMenu(), to: mainMenu)
        addSubmenu(named: "Window", submenu: makeWindowMenu(), to: mainMenu)
        return mainMenu
    }

    private func makeApplicationMenu() -> NSMenu {
        let menu = NSMenu(title: "WalkFlow-Mac")
        menu.addItem(commandItem(title: "Hide WalkFlow-Mac", action: #selector(hideApplication(_:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(commandItem(title: "Quit WalkFlow-Mac", action: #selector(quitApplication(_:)), keyEquivalent: "q"))
        return menu
    }

    private func makeFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.addItem(commandItem(title: "Close Window", action: #selector(closeMainWindow(_:)), keyEquivalent: "w"))
        return menu
    }

    private func makeWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        menu.addItem(commandItem(title: "Minimize", action: #selector(minimizeMainWindow(_:)), keyEquivalent: "m"))
        return menu
    }

    private func addSubmenu(named title: String, submenu: NSMenu, to mainMenu: NSMenu) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mainMenu.addItem(item)
        mainMenu.setSubmenu(submenu, for: item)
    }

    private func commandItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = [.command]
        item.target = self
        return item
    }
}
