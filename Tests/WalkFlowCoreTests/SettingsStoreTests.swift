import XCTest
@testable import WalkFlowCore

final class SettingsStoreTests: XCTestCase {
    func testDefaultSettingsAreLoadedWhenStoreIsEmpty() {
        let defaults = UserDefaults(suiteName: "SettingsStoreTests.empty")!
        defaults.removePersistentDomain(forName: "SettingsStoreTests.empty")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load(), .defaults)
    }

    func testSavedHUDPositionRoundTrips() {
        let defaults = UserDefaults(suiteName: "SettingsStoreTests.roundtrip")!
        defaults.removePersistentDomain(forName: "SettingsStoreTests.roundtrip")
        let store = SettingsStore(defaults: defaults)

        var settings = AppSettings.defaults
        settings.hud.savedOriginX = 1440
        settings.hud.savedOriginY = 24
        store.save(settings)

        XCTAssertEqual(store.load().hud.savedOriginX, 1440)
        XCTAssertEqual(store.load().hud.savedOriginY, 24)
    }
}
