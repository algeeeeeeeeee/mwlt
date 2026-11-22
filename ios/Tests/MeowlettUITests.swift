import XCTest

final class MeowlettUITests: XCTestCase {

    @MainActor
    private func launchUITestApp(_ app: XCUIApplication, additionalArguments: [String] = []) {
        app.launchArguments = ["-uitest-reset", "--mwlt-preview-mode"] + additionalArguments
        app.launch()
    }

    @MainActor
    private func recordHitPointDiagnostics(
        for element: XCUIElement,
        named name: String,
        in app: XCUIApplication
    ) {
        let frame = element.frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let candidates = app.descendants(matching: .any).allElementsBoundByIndex.compactMap { candidate -> String? in
            guard candidate.exists, candidate.frame.contains(center) else { return nil }
            return "type=\(candidate.elementType), label=\(candidate.label), identifier=\(candidate.identifier), enabled=\(candidate.isEnabled), hittable=\(candidate.isHittable), frame=\(candidate.frame)"
        }

        print("""
        [MeowlettHitPoint] name=\(name)
        target.type=\(element.elementType)
        target.label=\(element.label)
        target.identifier=\(element.identifier)
        target.enabled=\(element.isEnabled)
        target.hittable=\(element.isHittable)
        target.frame=\(frame)
        target.center=\(center)
        center.accessibility.frame-candidates:
        \(candidates.joined(separator: "\n"))
        overlays.sheet=\(app.sheets.firstMatch.exists), alert=\(app.alerts.firstMatch.exists), keyboard=\(app.keyboards.firstMatch.exists)
        target.debugDescription:
        \(element.debugDescription)
        """)
    }

    @MainActor
    private func captureAccessibilitySnapshot(
        named name: String,
        app: XCUIApplication,
        elements: [(String, XCUIElement)] = []
    ) {
        let elementDetails = elements.map { entry -> String in
            let element = entry.1
            let exists = element.exists
            let hittable = exists && element.isHittable
            let enabled = exists && element.isEnabled
            let frame = exists ? String(describing: element.frame) : "unavailable"
            let description = exists ? element.debugDescription : "<not in accessibility hierarchy>"
            return "\(entry.0): exists=\(exists), hittable=\(hittable), enabled=\(enabled), label=\(element.label), identifier=\(element.identifier), frame=\(frame)\n\(description)"
        }.joined(separator: "\n")

        let report = """
        SNAPSHOT: \(name)
        ELEMENTS:
        \(elementDetails)

        OVERLAYS:
        sheet=\(app.sheets.firstMatch.exists), alert=\(app.alerts.firstMatch.exists), keyboard=\(app.keyboards.firstMatch.exists)

        ACCESSIBILITY HIERARCHY:
        \(app.debugDescription)
        """

        print(report)
        XCTContext.runActivity(named: "Accessibility snapshot — \(name)") { activity in
            let attachment = XCTAttachment(string: report)
            attachment.name = "Accessibility snapshot — \(name)"
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    @MainActor
    private func waitForElement(
        _ element: XCUIElement,
        label: String,
        app: XCUIApplication,
        timeout: TimeInterval
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            captureAccessibilitySnapshot(
                named: "\(label)-missing",
                app: app,
                elements: [
                    ("target", element),
                    ("settingsHeader", app.buttons["mwlt.header.settings"]),
                    ("settingsHeading", app.staticTexts["mwlt.screen.settings"]),
                    ("quickAdd", app.buttons["mwlt.quickAdd"]),
                    ("sheet", app.sheets.firstMatch),
                    ("alert", app.alerts.firstMatch),
                    ("keyboard", app.keyboards.firstMatch)
                ]
            )
        }
        return exists
    }

    @MainActor
    private func assertSettingsScreenAppears(in app: XCUIApplication) {
        let heading = app.staticTexts["mwlt.screen.settings"]
        let appears = heading.waitForExistence(timeout: 8)
        if !appears {
            captureAccessibilitySnapshot(
                named: "settings-screen-did-not-open",
                app: app,
                elements: [
                    ("settingsHeader", app.buttons["mwlt.header.settings"]),
                    ("settingsHeading", heading),
                    ("quickAdd", app.buttons["mwlt.quickAdd"]),
                    ("sheet", app.sheets.firstMatch),
                    ("alert", app.alerts.firstMatch),
                    ("keyboard", app.keyboards.firstMatch)
                ]
            )
        }
        XCTAssertTrue(appears, "Settings screen did not appear after tapping the Settings header.")
    }
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
    private func tapSettingsHeader(in app: XCUIApplication) {
        let button = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Settings header button is missing.")
        XCTAssertTrue(button.isEnabled, "Settings header must remain enabled.")
        recordHitPointDiagnostics(for: button, named: "settings-header", in: app)

        // Runs #269 and #273 show the same 44×44 identifier-backed header in its
        // expected top-right frame, with no sheet/alert/keyboard. XCTest's
        // isHittable value intermittently reports false even though a center
        // coordinate event opens Settings. It selects a gesture; it is never
        // a pass criterion. The destination screen is asserted below.
        if button.isHittable {
            print("[MeowlettTapStrategy] Settings -> button.tap()")
            button.tap()
        } else {
            print("[MeowlettTapStrategy] Settings -> coordinate(center) fallback; identifier exists and enabled")
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        let opened = app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8)
        if !opened {
            captureAccessibilitySnapshot(
                named: "settings-screen-did-not-open-after-tap",
                app: app,
                elements: [
                    ("settingsHeader", button),
                    ("settingsHeading", app.staticTexts["mwlt.screen.settings"]),
                    ("sheet", app.sheets.firstMatch),
                    ("alert", app.alerts.firstMatch),
                    ("keyboard", app.keyboards.firstMatch)
                ]
            )
        }
        XCTAssertTrue(opened, "Settings header tap must open the Settings screen.")
    }

    @MainActor
    private func openSettingsDataSheet(in app: XCUIApplication) {
        launchUITestApp(app)

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 15))
        tapSettingsHeader(in: app)
        assertSettingsScreenAppears(in: app)

        let dataRow = app.buttons["mwlt.settings.data"]
        XCTAssertTrue(waitForElement(dataRow, label: "settings-data-row", app: app, timeout: 10), "Settings Data row is missing.")
        dataRow.tap()
        XCTAssertTrue(app.staticTexts["mwlt.settings.sheet.data.title"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testNativeOpeningSplashAppearsAndDismisses() {
        let app = XCUIApplication()
        launchUITestApp(app, additionalArguments: ["--mwlt-test-splash"])

        let splashTitle = app.staticTexts["mwlt.splash.title"]
        XCTAssertTrue(
            splashTitle.waitForExistence(timeout: 20),
            "The native Meowlett opening splash should appear on cold launch."
        )
        let continueButton = app.buttons["mwlt.splash.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8))
        continueButton.tap()

        XCTAssertTrue(
            app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 12),
            "The first app screen should be available after the splash finishes."
        )
        XCTAssertFalse(splashTitle.exists, "The opening splash should dismiss after Continue.")
    }

    @MainActor
    func testMainTabsQuickAddAndCalculatorPresentation() {
        let app = XCUIApplication()
        launchUITestApp(app)

        XCTAssertTrue(app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 15))
        let dashboardScroll = app.scrollViews.firstMatch
        XCTAssertTrue(dashboardScroll.waitForExistence(timeout: 8), "Dashboard scroll view is missing.")
        dashboardScroll.swipeUp()
        tapSettingsHeader(in: app)
        let dashboardTab = app.buttons["mwlt.tab.dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 8), "Dashboard navigation item should be available after Settings.")
        dashboardTab.tap()
        let dashboardSelected = expectation(
            for: NSPredicate(format: "value == %@", "selected"),
            evaluatedWith: dashboardTab,
            handler: nil
        )
        wait(for: [dashboardSelected], timeout: 8)
        XCTAssertEqual(dashboardTab.value as? String, "selected", "Dashboard tab must be selected after returning from Settings.")
        let returnedDashboardScroll = app.scrollViews.firstMatch
        XCTAssertTrue(returnedDashboardScroll.waitForExistence(timeout: 8), "Dashboard scroll view should return after navigating back.")
        returnedDashboardScroll.swipeDown()
        tapTab("transactions", app: app)
        tapTab("report", app: app)
        tapTab("date", app: app)

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        tapSettingsHeader(in: app)
        assertSettingsScreenAppears(in: app)

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
    func testSettingsNotificationsShowSystemPermissionStatus() {
        let app = XCUIApplication()
        launchUITestApp(app)

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 15))
        tapSettingsHeader(in: app)
        assertSettingsScreenAppears(in: app)

        let notificationsRow = app.buttons["mwlt.settings.notifications"]
        XCTAssertTrue(waitForElement(notificationsRow, label: "settings-notifications-row", app: app, timeout: 8), "Settings Notifications row is missing.")
        notificationsRow.tap()

        XCTAssertTrue(
            app.staticTexts["mwlt.settings.notifications.permissionStatus"].waitForExistence(timeout: 8),
            "The Notifications sheet should show the current iOS authorization status."
        )
    }

    @MainActor
    func testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss() {
        let app = XCUIApplication()
        launchUITestApp(app)

        let settingsButton = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 15))
        tapSettingsHeader(in: app)
        assertSettingsScreenAppears(in: app)

        func openAndClose(row: String, title: String, close: String) {
            let rowButton = app.buttons[row]
            XCTAssertTrue(
                waitForElement(rowButton, label: "settings-row-\\(row)", app: app, timeout: 10),
                "Missing Settings row: \\(row)"
            )
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
    func testQuickAddSavesTransactionAndShowsItInTransactionsList() {
        let app = XCUIApplication()
        let transactionName = "CI Flow " + String(UUID().uuidString.prefix(6))
        launchUITestApp(app)

        let quickAddButton = app.buttons["mwlt.quickAdd"]
        XCTAssertTrue(waitForElement(quickAddButton, label: "quick-add-button", app: app, timeout: 15))
        recordHitPointDiagnostics(for: quickAddButton, named: "quick-add-before-standard-tap", in: app)
        print("[MeowlettTapStrategy] Quick Add save flow -> button.tap()")
        quickAddButton.tap()

        let editorTitleBeforeSave = app.staticTexts["mwlt.transactionEditor.title"]
        let editorPresented = editorTitleBeforeSave.waitForExistence(timeout: 10)
        if !editorPresented {
            captureAccessibilitySnapshot(
                named: "quick-add-editor-did-not-present",
                app: app,
                elements: [
                    ("quickAdd", quickAddButton),
                    ("editorTitle", editorTitleBeforeSave),
                    ("amountField", app.textFields["mwlt.transactionEditor.amount"]),
                    ("descriptionField", app.textFields["mwlt.transactionEditor.description"]),
                    ("saveButton", app.buttons["mwlt.transactionEditor.save"]),
                    ("sheet", app.sheets.firstMatch),
                    ("alert", app.alerts.firstMatch),
                    ("keyboard", app.keyboards.firstMatch)
                ]
            )
        }
        XCTAssertTrue(editorPresented, "Quick Add should present the transaction editor before its fields are queried.")
        let amountField = app.textFields["mwlt.transactionEditor.amount"]
        let descriptionField = app.textFields["mwlt.transactionEditor.description"]
        let saveButton = app.buttons["mwlt.transactionEditor.save"]

        XCTAssertTrue(amountField.waitForExistence(timeout: 8))
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 8))
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))

        amountField.tap()
        amountField.typeText("24680")
        descriptionField.tap()
        descriptionField.typeText(transactionName)

        XCTAssertTrue(saveButton.isEnabled, "Save should enable after a positive amount and description are entered.")
        saveButton.tap()

        let editorTitle = app.staticTexts["mwlt.transactionEditor.title"]
        let editorClosed = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: editorTitle,
            handler: nil
        )
        wait(for: [editorClosed], timeout: 8)

        tapTab("transactions", app: app)
        XCTAssertTrue(
            app.staticTexts[transactionName].waitForExistence(timeout: 10),
            "The saved transaction should appear in the Transactions list."
        )
    }

    @MainActor
    func testSettingsHeaderStandardTapVersusCoordinateTap() {
        let app = XCUIApplication()
        launchUITestApp(app)

        var standardRecorded = false
        var standardReady = false
        var standardOpened = false
        var standardHittableBeforeWait = false
        var standardHittableAfterWait = false
        var standardTapAttempted = false

        XCTContext.runActivity(named: "Settings paired leg — standard button.tap()") { _ in
            let dashboardHeading = app.staticTexts["mwlt.screen.dashboard"]
            let dashboardTab = app.buttons["mwlt.tab.dashboard"]
            let standardButton = app.buttons["mwlt.header.settings"]

            // Wait for dashboard landmarks and the identifier-backed header before
            // measuring hit testing; this is an existence-based readiness wait, not sleep.
            let dashboardReady = dashboardHeading.waitForExistence(timeout: 15)
                && dashboardTab.waitForExistence(timeout: 10)
            standardHittableBeforeWait = standardButton.exists && standardButton.isHittable
            let headerExists = standardButton.waitForExistence(timeout: 10)
            standardReady = dashboardReady && headerExists
            standardHittableAfterWait = headerExists && standardButton.isHittable

            print("[MeowlettTapComparison] control=settings leg=standard phase=pre-tap dashboardReady=\(dashboardReady) headerExists=\(headerExists) hittableBeforeWait=\(standardHittableBeforeWait) hittableAfterWait=\(standardHittableAfterWait) timestamp=\(ISO8601DateFormatter().string(from: Date()))")

            if standardReady {
                XCTAssertTrue(standardButton.isEnabled, "Settings header must be enabled before standard tap.")
                recordHitPointDiagnostics(for: standardButton, named: "settings-header-standard-after-readiness-wait", in: app)
                standardTapAttempted = true

                // Capture a possible XCTest AX tap failure, but always measure the
                // destination. The final assertion still requires Settings to open.
                var options = XCTExpectedFailure.Options()
                options.isStrict = false
                XCTExpectFailure(
                    "Capture XCTest AX tap failure independently; Settings destination remains mandatory.",
                    options: options
                ) {
                    standardButton.tap()
                }
                standardOpened = app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8)
            }

            print("[MeowlettTapComparison] control=settings leg=standard opened=\(standardOpened) hittableBeforeTap=\(standardHittableAfterWait) tapAttempted=\(standardTapAttempted) timestamp=\(ISO8601DateFormatter().string(from: Date()))")
            standardRecorded = true
        }

        // Relaunch guarantees the coordinate leg starts independently, even if the
        // standard leg failed to open Settings.
        app.terminate()
        launchUITestApp(app)

        var coordinateRecorded = false
        var coordinateReady = false
        var coordinateHittableBeforeWait = false
        var coordinateHittableAfterWait = false
        var coordinateTapAttempted = false
        var coordinateOpened = false

        XCTContext.runActivity(named: "Settings paired leg — coordinate center") { _ in
            let dashboardHeading = app.staticTexts["mwlt.screen.dashboard"]
            let dashboardTab = app.buttons["mwlt.tab.dashboard"]
            let coordinateButton = app.buttons["mwlt.header.settings"]

            let dashboardReady = dashboardHeading.waitForExistence(timeout: 15)
                && dashboardTab.waitForExistence(timeout: 10)
            coordinateHittableBeforeWait = coordinateButton.exists && coordinateButton.isHittable
            let headerExists = coordinateButton.waitForExistence(timeout: 10)
            coordinateReady = dashboardReady && headerExists
            coordinateHittableAfterWait = headerExists && coordinateButton.isHittable

            print("[MeowlettTapComparison] control=settings leg=coordinate phase=pre-tap dashboardReady=\(dashboardReady) headerExists=\(headerExists) hittableBeforeWait=\(coordinateHittableBeforeWait) hittableAfterWait=\(coordinateHittableAfterWait) timestamp=\(ISO8601DateFormatter().string(from: Date()))")

            if coordinateReady {
                XCTAssertTrue(coordinateButton.isEnabled, "Settings header must be enabled before coordinate tap.")
                recordHitPointDiagnostics(for: coordinateButton, named: "settings-header-coordinate-after-readiness-wait", in: app)
                coordinateTapAttempted = true
                coordinateButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                coordinateOpened = app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8)
            }

            print("[MeowlettTapComparison] control=settings leg=coordinate opened=\(coordinateOpened) hittableBeforeTap=\(coordinateHittableAfterWait) tapAttempted=\(coordinateTapAttempted) timestamp=\(ISO8601DateFormatter().string(from: Date()))")
            coordinateRecorded = true
        }

        // Do not assert until both legs have emitted independent result records.
        XCTAssertTrue(standardRecorded, "The standard Settings leg must record a result.")
        XCTAssertTrue(coordinateRecorded, "The coordinate Settings leg must record a result.")
        XCTAssertTrue(standardReady, "The standard Settings leg must reach a ready dashboard/header state.")
        XCTAssertTrue(coordinateReady, "The coordinate Settings leg must reach a ready dashboard/header state.")
        XCTAssertTrue(standardTapAttempted, "The standard Settings tap must be attempted.")
        XCTAssertTrue(coordinateTapAttempted, "The coordinate Settings tap must be attempted.")
        XCTAssertTrue(standardOpened, "The standard button.tap() leg must open Settings.")
        XCTAssertTrue(coordinateOpened, "The coordinate-center leg must open Settings.")
        print("[MeowlettTapComparison] control=settings summary standardOpened=\(standardOpened) coordinateOpened=\(coordinateOpened) standardHittableBeforeWait=\(standardHittableBeforeWait) standardHittableAfterWait=\(standardHittableAfterWait) coordinateHittableBeforeWait=\(coordinateHittableBeforeWait) coordinateHittableAfterWait=\(coordinateHittableAfterWait)")
    }

    @MainActor
    func testQuickAddStandardTapVersusCoordinateTap() {
        let app = XCUIApplication()
        launchUITestApp(app)

        let standardButton = app.buttons["mwlt.quickAdd"]
        XCTAssertTrue(standardButton.waitForExistence(timeout: 15))
        recordHitPointDiagnostics(for: standardButton, named: "quick-add-before-button-tap", in: app)
        print("[MeowlettTapComparison] control=quick-add method=button.tap()")
        standardButton.tap()
        let standardOpened = app.staticTexts["mwlt.transactionEditor.title"].waitForExistence(timeout: 8)
        print("[MeowlettTapComparison] control=quick-add method=button.tap() opened=\(standardOpened)")

        app.terminate()
        launchUITestApp(app)

        let coordinateButton = app.buttons["mwlt.quickAdd"]
        XCTAssertTrue(coordinateButton.waitForExistence(timeout: 15))
        recordHitPointDiagnostics(for: coordinateButton, named: "quick-add-before-coordinate-tap", in: app)
        print("[MeowlettTapComparison] control=quick-add method=coordinate(center)")
        coordinateButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let coordinateOpened = app.staticTexts["mwlt.transactionEditor.title"].waitForExistence(timeout: 8)
        print("[MeowlettTapComparison] control=quick-add method=coordinate(center) opened=\(coordinateOpened)")
        XCTAssertTrue(coordinateOpened, "The coordinate-center tap must present Quick Add.")
    }



    @MainActor
    func testDatePreviewLaunchStartsOnDateTab() {
        let app = XCUIApplication()
        launchUITestApp(app, additionalArguments: ["--mwlt-preview-tab=date"])

        XCTAssertTrue(
            app.staticTexts["mwlt.screen.date"].waitForExistence(timeout: 15),
            "A direct Date preview launch should render the Date header on its first screen."
        )
        XCTAssertTrue(
            app.buttons["mwlt.date.addWishlist"].waitForExistence(timeout: 8),
            "A direct Date preview launch should render Date tab content."
        )
    }

    @MainActor
    func testDateWishlistSheetCanBeOpened() {
        let app = XCUIApplication()
        launchUITestApp(app)

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
