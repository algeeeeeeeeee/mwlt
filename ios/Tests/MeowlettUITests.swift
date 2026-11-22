import XCTest

final class MeowlettUITests: XCTestCase {
    @MainActor
    private func tapTab(_ tabID: String, app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let tab = app.buttons["mwlt.tab.\(tabID)"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing navigation tab: \(tabID)", file: file, line: line)
        tab.tap()

        let selectedExpectation = expectation(
            for: NSPredicate(format: "value == %@", "selected"),
            evaluatedWith: tab,
            handler: nil
        )
        wait(for: [selectedExpectation], timeout: 6)

        XCTAssertTrue(
            app.staticTexts["mwlt.screen.\(tabID)"].waitForExistence(timeout: 6),
            "The \(tabID) screen heading did not appear after selecting its navigation item.",
            file: file,
            line: line
        )
    }

    @MainActor
    func testMainTabsQuickAddAndCalculatorPresentation() {
        let app = XCUIApplication()
        app.launchArguments = ["--mwlt-preview-mode"]
        app.launch()

        XCTAssertTrue(app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 15))
        tapTab("transactions", app: app)
        tapTab("report", app: app)
        tapTab("date", app: app)

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
        XCTAssertTrue(app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8))

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

        XCTAssertTrue(app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 15))
        tapTab("date", app: app)

        let addWishlistButton = app.buttons["mwlt.date.addWishlist"]
        let dateScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(dateScrollView.waitForExistence(timeout: 8), "The Date screen scroll view is missing.")

        for _ in 0..<4 {
            if addWishlistButton.exists && addWishlistButton.isHittable { break }
            dateScrollView.swipeUp()
        }

        XCTAssertTrue(addWishlistButton.waitForExistence(timeout: 8), "The Date wishlist Add action is missing after scrolling.")
        XCTAssertTrue(addWishlistButton.isHittable, "The Date wishlist Add action is not hittable.")
        addWishlistButton.tap()

        XCTAssertTrue(
            app.staticTexts["mwlt.date.wishlist.title"].waitForExistence(timeout: 8),
            "The Date wishlist sheet did not appear."
        )
    }
}
