import XCTest

final class MeowlettUITests: XCTestCase {

    @MainActor
    private func capturePostSplashNavigationDiagnostics(_ app: XCUIApplication) {
        // The app content stays accessibility-hidden until RootView removes its splash overlay.
        let splashTitle = app.staticTexts["mwlt.splash.title"]
        if splashTitle.waitForExistence(timeout: 3) {
            let splashRemoved = expectation(
                for: NSPredicate(format: "exists == false"),
                evaluatedWith: splashTitle,
                handler: nil
            )
            let result = XCTWaiter.wait(for: [splashRemoved], timeout: 10)
            print("[MeowlettPostSplash] splashRemovalWait=\(result)")
        } else {
            let dashboardVisible = app.buttons["mwlt.tab.dashboard"].waitForExistence(timeout: 15)
            print("[MeowlettPostSplash] splashTitleNotObserved dashboardVisible=\(dashboardVisible)")
        }

        print("[MeowlettPostSplash] app.debugDescription BEGIN")
        print(app.debugDescription)
        print("[MeowlettPostSplash] app.debugDescription END")

        let targets: [(String, XCUIElement)] = [
            ("mwlt.tab.dashboard", app.buttons["mwlt.tab.dashboard"]),
            ("mwlt.tab.transactions", app.buttons["mwlt.tab.transactions"]),
            ("mwlt.tab.report", app.buttons["mwlt.tab.report"]),
            ("mwlt.tab.date", app.buttons["mwlt.tab.date"]),
            ("mwlt.header.settings", app.buttons["mwlt.header.settings"])
        ]
        for (identifier, element) in targets {
            let isExists = element.exists
            let isHittable = isExists && element.isHittable
            print("[MeowlettPostSplash] \(identifier) isExists=\(isExists) isHittable=\(isHittable)")
        }
    }

    @MainActor
    private func launchUITestApp(_ app: XCUIApplication, additionalArguments: [String] = []) {
        app.launchArguments = ["-uitest-reset", "--mwlt-preview-mode"] + additionalArguments
        app.launch()

        // The splash-specific test intentionally holds this overlay until Continue is tapped.
        let holdsSplash = additionalArguments.contains("--mwlt-test-splash")
            || additionalArguments.contains("--mwlt-preview-splash")
        if !holdsSplash {
            capturePostSplashNavigationDiagnostics(app)
        }
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
        capturePostSplashNavigationDiagnostics(app)

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

        // XCTest's AX tap can report kAXErrorCannotComplete for this fixed header.
        // Continue after that failure so the independent coordinate leg still runs;
        // the final assertions below require BOTH gestures to open Settings.
        let previousContinueAfterFailure = continueAfterFailure
        continueAfterFailure = true
        defer { continueAfterFailure = previousContinueAfterFailure }

        func logSettingsHitContext(
            leg: String,
            button: XCUIElement,
            app: XCUIApplication
        ) {
            let midpoint = CGPoint(x: 310, y: 91)
            let hierarchyLines = app.debugDescription.components(separatedBy: .newlines)
            let targetLine = hierarchyLines.firstIndex {
                $0.contains("mwlt.header.settings") || $0.contains("Pengaturan")
            }
            if let targetLine {
                let lowerBound = max(0, min(max(0, hierarchyLines.count - 15), targetLine - 7))
                let upperBound = min(hierarchyLines.count, lowerBound + 15)
                print("""
                [MeowlettTapComparison] control=settings leg=\(leg) hierarchyContext15Lines:
                \(hierarchyLines[lowerBound..<upperBound].joined(separator: "\n"))
                """)
            } else {
                print("[MeowlettTapComparison] control=settings leg=\(leg) hierarchyContext15Lines=TARGET_NOT_FOUND")
            }

            let coveringElements = app.descendants(matching: .any).allElementsBoundByIndex.filter {
                $0.exists && $0.frame.contains(midpoint)
            }
            let coveringSummary = coveringElements.map {
                "type=\($0.elementType) identifier=\($0.identifier) frame=\($0.frame) label=\($0.label)"
            }
            print("""
            [MeowlettTapComparison] control=settings leg=\(leg) midpoint=\(midpoint)
            midpoint.frameContains.count=\(coveringSummary.count)
            midpoint.frameContains:
            \(coveringSummary.joined(separator: "\n"))
            target.button.debugDescription:
            \(button.debugDescription)
            """)
        }

        launchUITestApp(app)

        var standardReady = false
        var standardHittableBeforeWait = false
        var standardHittableBeforeTap = false
        var standardTapAttempted = false
        var standardOpened = false
        var appearanceTapAttempted = false
        var appearanceTapSucceeded = false

        XCTContext.runActivity(named: "Settings paired leg — standard button.tap()") { _ in
            let dashboardTab = app.buttons["mwlt.tab.dashboard"]
            let standardButton = app.buttons["mwlt.header.settings"]

            let dashboardTabExists = dashboardTab.waitForExistence(timeout: 15)
            if dashboardTabExists {
                let selected = expectation(
                    for: NSPredicate(format: "value == %@", "selected"),
                    evaluatedWith: dashboardTab,
                    handler: nil
                )
                wait(for: [selected], timeout: 8)
            }
            let dashboardReady = dashboardTabExists && (dashboardTab.value as? String == "selected")

            standardHittableBeforeWait = standardButton.exists && standardButton.isHittable
            let headerExists = standardButton.waitForExistence(timeout: 10)
            standardHittableBeforeTap = headerExists && standardButton.isHittable
            standardReady = dashboardReady && headerExists && standardButton.isEnabled

            let appearanceButton = app.buttons["mwlt.header.appearance"]
            let appearanceExists = appearanceButton.waitForExistence(timeout: 10)
            let appearanceInitialValue = appearanceButton.value as? String
            let appearanceHittableBeforeTap = appearanceExists && appearanceButton.isHittable
            let appearanceFrameBeforeTap = appearanceExists ? String(describing: appearanceButton.frame) : "unavailable"
            let settingsFrameBeforeTap = headerExists ? String(describing: standardButton.frame) : "unavailable"

            print("[MeowlettTapComparison] control=settings leg=standard pre-tap appearanceExists=\(appearanceExists) appearanceIsHittable=\(appearanceHittableBeforeTap) appearanceFrame=\(appearanceFrameBeforeTap) settingsExists=\(headerExists) settingsIsHittable=\(standardHittableBeforeTap) settingsFrame=\(settingsFrameBeforeTap)")

            if appearanceExists && appearanceButton.isEnabled, let appearanceInitialValue {
                appearanceTapAttempted = true
                appearanceButton.tap()
                let appearanceChanged = expectation(
                    for: NSPredicate(format: "value != %@", appearanceInitialValue),
                    evaluatedWith: appearanceButton,
                    handler: nil
                )
                let appearanceWaitResult = XCTWaiter.wait(for: [appearanceChanged], timeout: 6)
                appearanceTapSucceeded = appearanceWaitResult == .completed
                print("[MeowlettTapComparison] control=appearance method=button.tap() attempted=\(appearanceTapAttempted) succeeded=\(appearanceTapSucceeded) valueBefore=\(appearanceInitialValue) valueAfter=\(appearanceButton.value ?? "nil") frame=\(appearanceButton.frame) isHittableAfter=\(appearanceButton.isHittable)")
            } else {
                print("[MeowlettTapComparison] control=appearance method=button.tap() attempted=false succeeded=false reason=missing-disabled-or-no-accessibility-value")
            }

            // Recheck Settings immediately before its standard tap, after the Appearance comparison.
            standardHittableBeforeTap = headerExists && standardButton.isHittable
            print("[MeowlettTapComparison] control=settings leg=standard phase=pre-tap-after-appearance dashboardReady=\(dashboardReady) headerExists=\(headerExists) hittableBeforeWait=\(standardHittableBeforeWait) hittableBeforeTap=\(standardHittableBeforeTap) frame=\(settingsFrameBeforeTap) enabled=\(headerExists && standardButton.isEnabled) appearanceTapAttempted=\(appearanceTapAttempted) appearanceTapSucceeded=\(appearanceTapSucceeded) timestamp=\(ISO8601DateFormatter().string(from: Date()))")

            if headerExists && standardButton.isEnabled {
                logSettingsHitContext(leg: "standard", button: standardButton, app: app)
                recordHitPointDiagnostics(for: standardButton, named: "settings-header-standard-before-tap", in: app)
                standardTapAttempted = true
                standardButton.tap()
                standardOpened = app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 3)
            }

            print("[MeowlettTapComparison] control=settings leg=standard opened=\(standardOpened) hittableBeforeWait=\(standardHittableBeforeWait) hittableBeforeTap=\(standardHittableBeforeTap) tapAttempted=\(standardTapAttempted) timestamp=\(ISO8601DateFormatter().string(from: Date()))")
        }

        // A fresh app launch gives the coordinate leg an independent initial state.
        app.terminate()
        launchUITestApp(app)

        var coordinateReady = false
        var coordinateHittableBeforeWait = false
        var coordinateHittableBeforeTap = false
        var coordinateTapAttempted = false
        var coordinateOpened = false

        XCTContext.runActivity(named: "Settings paired leg — coordinate center") { _ in
            let dashboardTab = app.buttons["mwlt.tab.dashboard"]
            let coordinateButton = app.buttons["mwlt.header.settings"]

            let dashboardTabExists = dashboardTab.waitForExistence(timeout: 15)
            if dashboardTabExists {
                let selected = expectation(
                    for: NSPredicate(format: "value == %@", "selected"),
                    evaluatedWith: dashboardTab,
                    handler: nil
                )
                wait(for: [selected], timeout: 8)
            }
            let dashboardReady = dashboardTabExists && (dashboardTab.value as? String == "selected")

            coordinateHittableBeforeWait = coordinateButton.exists && coordinateButton.isHittable
            let headerExists = coordinateButton.waitForExistence(timeout: 10)
            coordinateHittableBeforeTap = headerExists && coordinateButton.isHittable
            coordinateReady = dashboardReady && headerExists && coordinateButton.isEnabled

            print("[MeowlettTapComparison] control=settings leg=coordinate phase=pre-tap dashboardReady=\(dashboardReady) headerExists=\(headerExists) hittableBeforeWait=\(coordinateHittableBeforeWait) hittableBeforeTap=\(coordinateHittableBeforeTap) enabled=\(headerExists && coordinateButton.isEnabled) timestamp=\(ISO8601DateFormatter().string(from: Date()))")

            if headerExists && coordinateButton.isEnabled {
                logSettingsHitContext(leg: "coordinate", button: coordinateButton, app: app)
                recordHitPointDiagnostics(for: coordinateButton, named: "settings-header-coordinate-before-tap", in: app)
                coordinateTapAttempted = true
                coordinateButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                coordinateOpened = app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 3)
            }

            print("[MeowlettTapComparison] control=settings leg=coordinate opened=\(coordinateOpened) hittableBeforeWait=\(coordinateHittableBeforeWait) hittableBeforeTap=\(coordinateHittableBeforeTap) tapAttempted=\(coordinateTapAttempted) timestamp=\(ISO8601DateFormatter().string(from: Date()))")
        }

        // These final assertions run only after both independently recorded legs.
        // No expected-failure matcher converts a failed tap into a passing test.
        XCTAssertTrue(standardReady, "The standard Settings leg must reach an enabled Settings header from Dashboard.")
        XCTAssertTrue(coordinateReady, "The coordinate Settings leg must reach an enabled Settings header from Dashboard.")
        XCTAssertTrue(standardTapAttempted, "The standard Settings button.tap() gesture must be attempted.")
        XCTAssertTrue(coordinateTapAttempted, "The coordinate-center gesture must be attempted.")
        XCTAssertTrue(standardOpened, "The standard button.tap() leg must open Settings within 3 seconds.")
        XCTAssertTrue(coordinateOpened, "The coordinate-center leg must open Settings within 3 seconds.")
        print("[MeowlettTapComparison] control=settings summary appearanceTapAttempted=\(appearanceTapAttempted) appearanceTapSucceeded=\(appearanceTapSucceeded) standardOpened=\(standardOpened) coordinateOpened=\(coordinateOpened) standardHittableBeforeWait=\(standardHittableBeforeWait) standardHittableBeforeTap=\(standardHittableBeforeTap) coordinateHittableBeforeWait=\(coordinateHittableBeforeWait) coordinateHittableBeforeTap=\(coordinateHittableBeforeTap)")
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


    @MainActor
    func testPrimaryMenusAndHeaderUseStandardButtonTap() {
        let app = XCUIApplication()
        launchUITestApp(app)
        let dashboardTab = app.buttons["mwlt.tab.dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 15))
        let dashboardSelected = expectation(
            for: NSPredicate(format: "value == %@", "selected"),
            evaluatedWith: dashboardTab,
            handler: nil
        )
        wait(for: [dashboardSelected], timeout: 8)
        XCTAssertEqual(dashboardTab.value as? String, "selected", "Dashboard tab should already be selected after launch.")

        let dashboardIncomeEdit = app.buttons["mwlt.dashboard.income.edit"]
        XCTAssertTrue(
            dashboardIncomeEdit.waitForExistence(timeout: 8),
            "A Dashboard-specific control should be available on the Dashboard screen."
        )

        tapTab("transactions", app: app)
        tapTab("report", app: app)
        tapTab("date", app: app)

        let appearance = app.buttons["mwlt.header.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 8))
        let initialAppearance = appearance.value as? String
        XCTAssertNotNil(initialAppearance)
        appearance.tap()
        let changed = expectation(
            for: NSPredicate(format: "value != %@", initialAppearance ?? ""),
            evaluatedWith: appearance,
            handler: nil
        )
        wait(for: [changed], timeout: 8)

        let settings = app.buttons["mwlt.header.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.staticTexts["mwlt.screen.settings"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testDashboardBudgetEditorUsesStandardButtonTap() {
        let app = XCUIApplication()
        launchUITestApp(app)
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let budget = app.buttons["mwlt.dashboard.budget.edit"]
        for _ in 0..<5 {
            if budget.exists && budget.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(budget.waitForExistence(timeout: 8))
        budget.tap()
        XCTAssertTrue(app.staticTexts["mwlt.dashboard.moneyEntry.title"].waitForExistence(timeout: 8))
        let cancel = app.buttons["mwlt.dashboard.moneyEntry.cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        cancel.tap()
    }

    @MainActor
    func testReportStoryExportModalUsesStandardButtonTap() {
        let app = XCUIApplication()
        launchUITestApp(app)
        tapTab("report", app: app)
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 8))
        let export = app.buttons["mwlt.reports.exportImage"]
        for _ in 0..<5 {
            if export.exists && export.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(export.waitForExistence(timeout: 8))
        export.tap()
        let cancel = app.buttons["mwlt.reports.story.cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        cancel.tap()
    }

    @MainActor
    func testInstallmentsMenuUsesStandardButtonTap() {
        let app = XCUIApplication()
        launchUITestApp(app)
        tapTab("transactions", app: app)
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 8))
        let installments = app.buttons["mwlt.transactions.installments"]
        for _ in 0..<6 {
            if installments.exists && installments.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(installments.waitForExistence(timeout: 8))
        installments.tap()
        XCTAssertTrue(app.descendants(matching: .any)["mwlt.transactions.installments.title"].waitForExistence(timeout: 8))
        let close = app.buttons["mwlt.transactions.installments.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        close.tap()
    }

    @MainActor
    func testSplitBillsMenuUsesStandardButtonTap() {
        let app = XCUIApplication()
        launchUITestApp(app)
        tapTab("transactions", app: app)
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 8))
        let splitBills = app.buttons["mwlt.transactions.splitBills"]
        for _ in 0..<6 {
            if splitBills.exists && splitBills.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(splitBills.waitForExistence(timeout: 8))
        splitBills.tap()
        XCTAssertTrue(app.descendants(matching: .any)["mwlt.transactions.splitBills.title"].waitForExistence(timeout: 8))
        let close = app.buttons["mwlt.transactions.splitBills.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        close.tap()
    }

}
