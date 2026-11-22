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
    private func openSettingsDataSheet(in app: XCUIApplication) {
        app.launchArguments = ["--mwlt-preview-mode"]
        app.launch()

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 15))
        settingsButton.tap()
        XCTAssertTrue(app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8))

        let dataRow = app.buttons["mwlt.settings.data"]
        XCTAssertTrue(dataRow.waitForExistence(timeout: 10))
        dataRow.tap()
        XCTAssertTrue(app.staticTexts["mwlt.settings.sheet.data.title"].waitForExistence(timeout: 10))
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
    func testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss() {
        let app = XCUIApplication()
        app.launchArguments = ["--mwlt-preview-mode"]
        app.launch()

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 15))
        settingsButton.tap()
        XCTAssertTrue(app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8))

        func openAndClose(row: String, title: String, close: String) {
            let rowButton = app.buttons[row]
            XCTAssertTrue(rowButton.waitForExistence(timeout: 10), "Missing Settings row: \(row)")
            rowButton.tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10), "Settings sheet did not open: \(title)")
            let closeButton = app.buttons[close]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 8), "Missing close control: \\(close)")
            closeButton.tap()
            XCTAssertTrue(rowButton.waitForExistence(timeout: 8), "Settings root did not return after closing: \(row)")
        }

        openAndClose(
            row: "mwlt.settings.appearance",
            title: "mwlt.settings.sheet.appearance.title",
            close: "mwlt.settings.sheet.appearance.close"
        )
        openAndClose(
            row: "mwlt.settings.notifications",
            title: "mwlt.settings.sheet.notifications.title",
            close: "mwlt.settings.sheet.notifications.close"
        )

        let categoryRow = app.buttons["mwlt.settings.category"]
        XCTAssertTrue(categoryRow.waitForExistence(timeout: 10))
        categoryRow.tap()
        XCTAssertTrue(app.staticTexts["mwlt.settings.sheet.category.title"].waitForExistence(timeout: 10))

        let budgetsButton = app.buttons["mwlt.settings.category.budgets"]
        XCTAssertTrue(budgetsButton.waitForExistence(timeout: 8))
        budgetsButton.tap()
        XCTAssertTrue(
            app.staticTexts["mwlt.settings.sheet.budgets.title"].waitForExistence(timeout: 10),
            "The Spending Limits submenu did not open."
        )
        let budgetsClose = app.buttons["mwlt.settings.sheet.budgets.close"]
        XCTAssertTrue(budgetsClose.waitForExistence(timeout: 8))
        budgetsClose.tap()

        XCTAssertTrue(categoryRow.waitForExistence(timeout: 8))
        categoryRow.tap()
        XCTAssertTrue(app.staticTexts["mwlt.settings.sheet.category.title"].waitForExistence(timeout: 8))

        let manageCategoriesButton = app.buttons["mwlt.settings.category.manage"]
        XCTAssertTrue(manageCategoriesButton.waitForExistence(timeout: 8))
        manageCategoriesButton.tap()
        XCTAssertTrue(
            app.staticTexts["mwlt.settings.sheet.categoryManager.title"].waitForExistence(timeout: 10),
            "The Manage Categories submenu did not open."
        )
        let manageClose = app.buttons["mwlt.settings.sheet.categoryManager.close"]
        XCTAssertTrue(manageClose.waitForExistence(timeout: 8))
        manageClose.tap()

        let dataRow = app.buttons["mwlt.settings.data"]
        XCTAssertTrue(dataRow.waitForExistence(timeout: 8))
        dataRow.tap()
        XCTAssertTrue(app.staticTexts["mwlt.settings.sheet.data.title"].waitForExistence(timeout: 10))

        XCTAssertTrue(app.buttons["mwlt.settings.data.backup"].exists, "Backup Data action is missing.")
        XCTAssertTrue(app.buttons["mwlt.settings.data.restore"].exists, "Restore Backup action is missing.")
        XCTAssertTrue(app.buttons["mwlt.settings.data.reset"].exists, "Reset All Data action is missing.")

        let dataClose = app.buttons["mwlt.settings.sheet.data.close"]
        XCTAssertTrue(dataClose.waitForExistence(timeout: 8))
        dataClose.tap()
        XCTAssertTrue(dataRow.waitForExistence(timeout: 8), "Settings root did not return after closing Data.")
    }

    @MainActor
    func testSettingsBackupActionBuildsAndRequestsExport() {
        let app = XCUIApplication()
        openSettingsDataSheet(in: app)

        let backupButton = app.buttons["mwlt.settings.data.backup"]
        XCTAssertTrue(backupButton.waitForExistence(timeout: 8))
        backupButton.tap()

        let exportRequested = expectation(
            for: NSPredicate(format: "value == %@", "presented"),
            evaluatedWith: backupButton,
            handler: nil
        )
        wait(for: [exportRequested], timeout: 8)
        XCTAssertEqual(backupButton.value as? String, "presented")
    }

    @MainActor
    func testSettingsRestoreActionRequestsImport() {
        let app = XCUIApplication()
        openSettingsDataSheet(in: app)

        let restoreButton = app.buttons["mwlt.settings.data.restore"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 8))
        restoreButton.tap()

        let importRequested = expectation(
            for: NSPredicate(format: "value == %@", "presented"),
            evaluatedWith: restoreButton,
            handler: nil
        )
        wait(for: [importRequested], timeout: 8)
        XCTAssertEqual(restoreButton.value as? String, "presented")
    }

    @MainActor
    func testSettingsResetRequiresConfirmationAndCanBeCancelled() {
        let app = XCUIApplication()
        openSettingsDataSheet(in: app)

        let dataTitle = app.staticTexts["mwlt.settings.sheet.data.title"]
        let resetButton = app.buttons["mwlt.settings.data.reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 8))
        resetButton.tap()

        let confirmation = app.staticTexts["mwlt.settings.data.confirmation.message"]
        XCTAssertTrue(
            confirmation.waitForExistence(timeout: 8),
            "Reset did not show its confirmation prompt."
        )

        let cancelButton = app.buttons["mwlt.settings.data.confirmation.cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 8))
        cancelButton.tap()

        XCTAssertTrue(dataTitle.waitForExistence(timeout: 8))
        XCTAssertFalse(confirmation.exists, "Reset confirmation should close after cancellation.")
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
