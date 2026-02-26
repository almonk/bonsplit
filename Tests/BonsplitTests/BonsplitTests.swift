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

    // MARK: - Zoom 

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

    @MainActor
    func testDefaultConfigPreserveZoomIsFalse() {
        let config = BonsplitConfiguration.default
        XCTAssertFalse(config.preserveZoomOnNavigation)
    }

    @MainActor
    func testConfigAcceptsPreserveZoomOnNavigation() {
        let config = BonsplitConfiguration(preserveZoomOnNavigation: true)
        XCTAssertTrue(config.preserveZoomOnNavigation)
    }

    @MainActor
    func testSplitWhileZoomedClearsZoom() {
        let (controller, paneA, _) = makeTwoPaneController()

        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        controller.splitPane(paneA, orientation: .horizontal)
        XCTAssertFalse(controller.isZoomed)
    }

    @MainActor
    func testCloseZoomedPaneClearsZoom() {
        let (controller, paneA, _) = makeTwoPaneController()

        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        controller.closePane(paneA)
        XCTAssertFalse(controller.isZoomed)
        XCTAssertNil(controller.zoomedPaneId)
    }

    @MainActor
    func testCloseSiblingPreservesZoom() {
        let (controller, paneA, paneB) = makeThreePaneController()

        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        // Close a sibling — zoom should survive
        controller.closePane(paneB)
        XCTAssertTrue(controller.isZoomed)
        XCTAssertEqual(controller.zoomedPaneId, paneA)
    }

    @MainActor
    func testCloseSiblingCollapseClearsZoom() {
        let (controller, paneA, paneB) = makeTwoPaneController()

        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        // Close the only sibling — tree collapses to single pane
        controller.closePane(paneB)
        XCTAssertFalse(controller.isZoomed)
    }

    @MainActor
    func testNavigateWhileZoomedUnzooms() {
        let (controller, paneA, _) = makeTwoPaneController()
        // Focus paneA and zoom it
        controller.focusPane(paneA)
        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        controller.navigateFocus(direction: .right)
        XCTAssertFalse(controller.isZoomed)
    }

    @MainActor
    func testNavigateWhileZoomedPreservesZoom() {
        let config = BonsplitConfiguration(preserveZoomOnNavigation: true)
        let controller = BonsplitController(configuration: config)
        let paneA = controller.focusedPaneId!
        controller.splitPane(paneA, orientation: .horizontal)
        let paneB = controller.focusedPaneId!
        // Fix divider so both panes have real bounds
        if let split = controller.internalController.allSplits.first {
            split.dividerPosition = 0.5
        }

        controller.focusPane(paneA)
        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.isZoomed)

        controller.navigateFocus(direction: .right)
        XCTAssertTrue(controller.isZoomed)
        XCTAssertEqual(controller.zoomedPaneId, paneB)
    }

    // MARK: - Test Helpers

    @MainActor
    private func makeThreePaneController() -> (BonsplitController, PaneID, PaneID) {
        let controller = BonsplitController()
        let paneA = controller.focusedPaneId!
        controller.splitPane(paneA, orientation: .horizontal)
        let paneB = controller.focusedPaneId!
        // Fix divider position for geometry calculations
        if let split = controller.internalController.allSplits.first {
            split.dividerPosition = 0.5
        }
        // Split paneB to get a third pane — paneA is still intact
        controller.splitPane(paneB, orientation: .horizontal)
        if let splits = controller.internalController.allSplits.last {
            splits.dividerPosition = 0.5
        }
        // Returns paneA and paneB (paneC exists but we don't need its ID)
        return (controller, paneA, paneB)
    }

    @MainActor
    private func makeTwoPaneController() -> (BonsplitController, PaneID, PaneID) {
        let controller = BonsplitController()
        let paneA = controller.focusedPaneId!
        controller.splitPane(paneA, orientation: .horizontal)
        // focus moves to new pane after split
        let paneB = controller.focusedPaneId!
        // Fix divider position (starts at 1.0 for animation, set to 0.5 for test geometry)
        if let split = controller.internalController.allSplits.first {
            split.dividerPosition = 0.5
        }
        return (controller, paneA, paneB)
    }
}
