import XCTest
@testable import Bonsplit

final class BonsplitTests: XCTestCase {

    @MainActor
    func testControllerCreation() {
        let controller = BonsplitController()
        XCTAssertNotNil(controller.focusedPaneId)
    }

    @MainActor
    func testTabCreation() {
        let controller = BonsplitController()
        let tabId = controller.createTab(title: "Test Tab", icon: "doc")
        XCTAssertNotNil(tabId)
    }

    @MainActor
    func testTabRetrieval() {
        let controller = BonsplitController()
        let tabId = controller.createTab(title: "Test Tab", icon: "doc")!
        let tab = controller.tab(tabId)
        XCTAssertEqual(tab?.title, "Test Tab")
        XCTAssertEqual(tab?.icon, "doc")
    }

    @MainActor
    func testTabUpdate() {
        let controller = BonsplitController()
        let tabId = controller.createTab(title: "Original", icon: "doc")!

        controller.updateTab(tabId, title: "Updated", isDirty: true)

        let tab = controller.tab(tabId)
        XCTAssertEqual(tab?.title, "Updated")
        XCTAssertEqual(tab?.isDirty, true)
    }

    @MainActor
    func testTabClose() {
        let controller = BonsplitController()
        let tabId = controller.createTab(title: "Test Tab", icon: "doc")!

        let closed = controller.closeTab(tabId)

        XCTAssertTrue(closed)
        XCTAssertNil(controller.tab(tabId))
    }

    @MainActor
    func testConfiguration() {
        let config = BonsplitConfiguration(
            allowSplits: false,
            allowCloseTabs: true
        )
        let controller = BonsplitController(configuration: config)

        XCTAssertFalse(controller.configuration.allowSplits)
        XCTAssertTrue(controller.configuration.allowCloseTabs)
    }

    // MARK: - Zoom Tests

    @MainActor
    func testToggleZoomSinglePaneIsNoOp() {
        let controller = BonsplitController()
        let svc = controller.internalController

        let result = svc.toggleZoom(paneId: svc.focusedPaneId)
        XCTAssertFalse(result)
        XCTAssertNil(svc.zoomedPaneId)
    }

    @MainActor
    func testToggleZoomWithTwoPanes() {
        let (controller, paneA, _) = makeTwoPaneController()
        let svc = controller.internalController

        let result = svc.toggleZoom(paneId: paneA)
        XCTAssertTrue(result)
        XCTAssertEqual(svc.zoomedPaneId, paneA)
    }

    @MainActor
    func testToggleZoomSamePaneUnzooms() {
        let (controller, paneA, _) = makeTwoPaneController()
        let svc = controller.internalController

        svc.toggleZoom(paneId: paneA)
        let result = svc.toggleZoom(paneId: paneA)
        XCTAssertTrue(result)
        XCTAssertNil(svc.zoomedPaneId)
    }

    @MainActor
    func testToggleZoomDifferentPaneMovesZoom() {
        let (controller, paneA, paneB) = makeTwoPaneController()
        let svc = controller.internalController

        svc.toggleZoom(paneId: paneA)
        let result = svc.toggleZoom(paneId: paneB)
        XCTAssertTrue(result)
        XCTAssertEqual(svc.zoomedPaneId, paneB)
    }

    @MainActor
    func testUnzoomClearsState() {
        let (controller, paneA, _) = makeTwoPaneController()
        let svc = controller.internalController

        svc.toggleZoom(paneId: paneA)
        XCTAssertNotNil(svc.zoomedPaneId)
        svc.unzoom()
        XCTAssertNil(svc.zoomedPaneId)
    }

    // MARK: - Zoom Public API Tests

    @MainActor
    func testPublicToggleZoomReflectsState() {
        let (controller, paneA, _) = makeTwoPaneController()

        let result = controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(result)
        XCTAssertTrue(controller.isZoomed)
        XCTAssertEqual(controller.zoomedPaneId, paneA)
    }

    @MainActor
    func testPublicToggleZoomDefaultsToFocusedPane() {
        let (controller, _, paneB) = makeTwoPaneController()
        // paneB is focused after split
        XCTAssertEqual(controller.focusedPaneId, paneB)

        let result = controller.toggleZoom()
        XCTAssertTrue(result)
        XCTAssertEqual(controller.zoomedPaneId, paneB)
    }

    @MainActor
    func testPublicUnzoomClearsState() {
        let (controller, paneA, _) = makeTwoPaneController()

        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)
        controller.unzoom()
        XCTAssertFalse(controller.isZoomed)
        XCTAssertNil(controller.zoomedPaneId)
    }

    @MainActor
    func testIsZoomedReflectsState() {
        let (controller, paneA, _) = makeTwoPaneController()

        XCTAssertFalse(controller.isZoomed)
        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)
        controller.toggleZoom(paneId: paneA)
        XCTAssertFalse(controller.isZoomed)
    }

    // MARK: - Test Helpers

    @MainActor
    private func makeTwoPaneController() -> (BonsplitController, PaneID, PaneID) {
        let controller = BonsplitController()
        let paneA = controller.focusedPaneId!
        controller.splitPane(paneA, orientation: .horizontal)
        // focus moves to new pane after split
        let paneB = controller.focusedPaneId! 
        return (controller, paneA, paneB)
    }
}
