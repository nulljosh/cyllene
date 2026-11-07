import XCTest

/// Drives the App Review screen recording: launch, connect a key, the app list, one app's
/// versions and review status, Settings, then disconnecting the key. Values come from the
/// environment so no key ever lives in the repo. Run with CYLLENE_KEY_ID and CYLLENE_ISSUER_ID set
/// and the .p8 already in the simulator's Files app.
final class ReviewWalkthrough: XCTestCase {
    func testWalkthrough() throws {
        let env = ProcessInfo.processInfo.environment
        let keyID = try XCTUnwrap(env["CYLLENE_KEY_ID"]), issuer = try XCTUnwrap(env["CYLLENE_ISSUER_ID"])
        let app = XCUIApplication()
        app.launch()
        pause(2)

        // Intro, if it shows.
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 4) { skip.tap(); pause(1) }

        // Connect the key.
        let keyField = app.textFields["Key ID"]
        XCTAssertTrue(keyField.waitForExistence(timeout: 10))
        keyField.tap(); keyField.typeText(keyID)
        let issuerField = app.textFields["Issuer ID"]
        issuerField.tap(); issuerField.typeText(issuer)
        pause(1)
        app.buttons["Import .p8 file"].tap()
        // The picker opens on Recents; the key file sits in Browse, On My iPhone.
        let any = app.descendants(matching: .any)
        let file = any.matching(NSPredicate(format: "label BEGINSWITH 'AuthKey_'")).firstMatch
        if !file.waitForExistence(timeout: 4) {
            let browse = any.matching(NSPredicate(format: "label == 'Browse'")).firstMatch
            if browse.waitForExistence(timeout: 6) { browse.tap(); pause(1) }
            let local = any.matching(NSPredicate(format: "label == 'On My iPhone'")).firstMatch
            if local.waitForExistence(timeout: 6) { local.tap(); pause(1) }
        }
        XCTAssertTrue(file.waitForExistence(timeout: 10))
        file.tap()
        XCTAssertTrue(app.buttons["Key file loaded"].waitForExistence(timeout: 10))
        pause(1)
        app.buttons["Connect"].tap()

        // The app list, then one app's versions and review status.
        let apps = app.navigationBars["Apps"]
        XCTAssertTrue(apps.waitForExistence(timeout: 30))
        pause(3)
        let row = app.cells.element(boundBy: 0)
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()
        pause(5)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        pause(1)

        // Status, then Settings, then disconnect.
        app.tabBars.buttons["Status"].tap(); pause(3)
        app.tabBars.buttons["Settings"].tap(); pause(3)
        app.buttons["Disconnect key"].tap(); pause(1)
        app.buttons["Disconnect"].tap()
        XCTAssertTrue(app.textFields["Key ID"].waitForExistence(timeout: 10))
        pause(2)
    }

    private func pause(_ s: Double) { Thread.sleep(forTimeInterval: s) }
}
