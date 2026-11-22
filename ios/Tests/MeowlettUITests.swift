import XCTest

final class MeowlettUITests: XCTestCase {
    @MainActor
    func testMainTabsQuickAddAndCalculatorPresentation() {
        let app = XCUIApplication()
        app.launchArguments = ["--mwlt-preview-mode"]
        app.launch()

        XCTAssertTrue(app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 10))

        let tabChecks: [(String, String)] = [
            ("transactions", "Transaksi"),
            ("report", "Laporan"),
            ("date", "Date")
        ]

        for (tabID, expectedHeading) in tabChecks {
            let tab = app.buttons["mwlt.tab.\(tabID)"]
            XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing navigation tab: \(tabID)")
            tab.tap()
            XCTAssertTrue(
                app.staticTexts[expectedHeading].waitForExistence(timeout: 8),
                "The \(tabID) screen did not appear after tapping its navigation item."
            )
        }

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
        XCTAssertTrue(app.staticTexts["Pengaturan"].waitForExistence(timeout: 8))

        let quickAddButton = app.buttons["mwlt.quickAdd"]
        XCTAssertTrue(quickAddButton.waitForExistence(timeout: 10))
        quickAddButton.tap()

        let editorTitle = app.staticTexts["mwlt.transactionEditor.title"]
        XCTAssertTrue(editorTitle.waitForExistence(timeout: 8), "Quick Add did not open the transaction editor.")

        let calculatorButton = app.buttons["mwlt.transactionEditor.calculator"]
        XCTAssertTrue(calculatorButton.waitForExistence(timeout: 8), "The amount calculator button is missing.")
        calculatorButton.tap()

        XCTAssertTrue(
            app.buttons["Gunakan hasil"].waitForExistence(timeout: 8),
            "The calculator sheet did not appear."
        )
        let calculatorCancel = app.buttons["mwlt.calculator.cancel"]
        XCTAssertTrue(calculatorCancel.waitForExistence(timeout: 8))
        calculatorCancel.tap()

        XCTAssertTrue(editorTitle.waitForExistence(timeout: 8), "The transaction editor did not return after dismissing the calculator.")
    }

    @MainActor
    func testDateWishlistSheetCanBeOpened() {
        let app = XCUIApplication()
        app.launchArguments = ["--mwlt-preview-mode"]
        app.launch()

        let dateTab = app.buttons["mwlt.tab.date"]
        XCTAssertTrue(dateTab.waitForExistence(timeout: 10))
        dateTab.tap()

        let addWishlistButton = app.buttons["mwlt.date.addWishlist"]
        XCTAssertTrue(addWishlistButton.waitForExistence(timeout: 10), "The Date wishlist Add action is missing.")
        addWishlistButton.tap()

        XCTAssertTrue(
            app.staticTexts["mwlt.date.wishlist.title"].waitForExistence(timeout: 8),
            "The Date wishlist sheet did not appear."
        )
    }
}
