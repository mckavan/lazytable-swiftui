//
//  PinnedTableVerifyUITests.swift
//  lazytableUITests
//
//  Drives the pinned-table demo and captures screenshots for manual verification.
//

import XCTest

final class PinnedTableVerifyUITests: XCTestCase {
    @MainActor
    func testPinnedHeadersStickWhileScrolling() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["Pinned columns and rows"].tap()
        XCTAssertTrue(app.staticTexts["Item"].waitForExistence(timeout: 5), "Header corner cell should appear")
        XCTAssertTrue(app.staticTexts["Item #1"].exists, "First data row should be visible initially")
        XCTAssertTrue(app.staticTexts["Total"].exists, "Pinned footer should be visible initially")
        saveScreenshot(app, name: "1-initial")

        let scroll = app.scrollViews.firstMatch
        scroll.swipeUp(velocity: .fast)
        scroll.swipeUp(velocity: .fast)
        saveScreenshot(app, name: "2-scrolled-down")

        XCTAssertTrue(app.staticTexts["Item"].exists, "Header corner must stay pinned after vertical scroll")
        XCTAssertTrue(app.staticTexts["Stat 1"].exists, "Header row must stay pinned after vertical scroll")
        XCTAssertFalse(app.staticTexts["Item #1"].exists, "First data row should have scrolled away")
        XCTAssertTrue(app.staticTexts["Total"].exists, "Footer must stay pinned after vertical scroll")

        scroll.swipeLeft(velocity: .fast)
        scroll.swipeLeft(velocity: .fast)
        saveScreenshot(app, name: "3-scrolled-diagonal")

        XCTAssertTrue(app.staticTexts["Item"].exists, "Corner cell must stay pinned after horizontal scroll")
        XCTAssertFalse(app.staticTexts["Stat 1"].exists, "First stat column should have scrolled away")
        let pinnedItemCells = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Item #'"))
        XCTAssertGreaterThan(pinnedItemCells.count, 0, "Pinned name column must stay visible after horizontal scroll")

        // Programmatic scroll via the toolbar menu.
        app.buttons["scope"].firstMatch.tap()
        app.buttons["Scroll to top leading"].tap()
        XCTAssertTrue(app.staticTexts["Item #1"].waitForExistence(timeout: 5), "animateToCell should return to origin")
        XCTAssertTrue(app.staticTexts["Stat 1"].exists)
        saveScreenshot(app, name: "4-after-scroll-to-origin")
    }

    @MainActor
    private func saveScreenshot(_ app: XCUIApplication, name: String) {
        let png = app.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "/tmp/lazytable-verify-\(name).png"))
    }
}
