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
    func testZoomToggle() {
        // Single pane — no-op
        let singleController = BonsplitController()
        XCTAssertFalse(singleController.toggleZoom())
        XCTAssertFalse(singleController.isZoomed)

        // Two panes — full toggle lifecycle
        let (controller, paneA, paneB) = makeTwoPaneController()
        XCTAssertFalse(controller.isZoomed)

        // Zoom on
        XCTAssertTrue(controller.toggleZoom(paneId: paneA))
        XCTAssertTrue(controller.isZoomed)
        XCTAssertEqual(controller.zoomedPaneId, paneA)

        // Toggle same pane — zoom off
        XCTAssertTrue(controller.toggleZoom(paneId: paneA))
        XCTAssertFalse(controller.isZoomed)

        // Move zoom between panes
        controller.toggleZoom(paneId: paneA)
        XCTAssertTrue(controller.toggleZoom(paneId: paneB))
        XCTAssertEqual(controller.zoomedPaneId, paneB)

        // Defaults to focused pane
        controller.unzoom()
        controller.focusPane(paneA)
        controller.toggleZoom()
        XCTAssertEqual(controller.zoomedPaneId, paneA)

        // Explicit unzoom
        controller.unzoom()
        XCTAssertFalse(controller.isZoomed)
        XCTAssertNil(controller.zoomedPaneId)
    }

    @MainActor
    func testZoomClearsOnStructuralChanges() {
        // Split while zoomed → clears
        let (c1, paneA1, _) = makeTwoPaneController()
        c1.toggleZoom(paneId: paneA1)
        c1.splitPane(paneA1, orientation: .horizontal)
        XCTAssertFalse(c1.isZoomed)

        // Close zoomed pane → clears
        let (c2, paneA2, _) = makeTwoPaneController()
        c2.toggleZoom(paneId: paneA2)
        c2.closePane(paneA2)
        XCTAssertFalse(c2.isZoomed)

        // Close sibling (3 panes) → preserves zoom
        let (c3, paneA3, paneB3) = makeThreePaneController()
        c3.toggleZoom(paneId: paneA3)
        c3.closePane(paneB3)
        XCTAssertTrue(c3.isZoomed)
        XCTAssertEqual(c3.zoomedPaneId, paneA3)

        // Close only sibling (collapse to 1 pane) → clears
        let (c4, paneA4, paneB4) = makeTwoPaneController()
        c4.toggleZoom(paneId: paneA4)
        c4.closePane(paneB4)
        XCTAssertFalse(c4.isZoomed)
    }

    @MainActor
    func testZoomSnapshots() {
        let (controller, paneA, _) = makeTwoPaneController()

        // Not zoomed — all panes in layout
        let normal = controller.layoutSnapshot()
        XCTAssertEqual(normal.panes.count, 2)
        XCTAssertFalse(normal.isZoomed)
        XCTAssertNil(normal.zoomedPaneId)

        // Zoomed — single pane in layout, full tree preserved
        controller.toggleZoom(paneId: paneA)
        let zoomed = controller.layoutSnapshot()
        XCTAssertEqual(zoomed.panes.count, 1)
        XCTAssertTrue(zoomed.isZoomed)
        XCTAssertEqual(zoomed.zoomedPaneId, paneA.id.uuidString)

        // Tree snapshot always returns full tree
        let tree = controller.treeSnapshot()
        if case .split(let split) = tree {
            XCTAssertNotNil(split)
        } else {
            XCTFail("Expected split node at root, got pane")
        }
    }

    @MainActor
    func testZoomNavigation() {
        // Default: navigate unzooms
        let (c1, paneA1, _) = makeTwoPaneController()
        c1.focusPane(paneA1)
        c1.toggleZoom(paneId: paneA1)
        c1.navigateFocus(direction: .right)
        XCTAssertFalse(c1.isZoomed)

        // Preserve mode: navigate moves zoom
        let config = BonsplitConfiguration(preserveZoomOnNavigation: true)
        let c2 = BonsplitController(configuration: config)
        let paneA2 = c2.focusedPaneId!
        c2.splitPane(paneA2, orientation: .horizontal)
        let paneB2 = c2.focusedPaneId!
        if let split = c2.internalController.allSplits.first {
            split.dividerPosition = 0.5
        }
        c2.focusPane(paneA2)
        c2.toggleZoom(paneId: paneA2)
        c2.navigateFocus(direction: .right)
        XCTAssertTrue(c2.isZoomed)
        XCTAssertEqual(c2.zoomedPaneId, paneB2)
    }

    @MainActor
    func testZoomConfiguration() {
        XCTAssertFalse(BonsplitConfiguration.default.preserveZoomOnNavigation)
        XCTAssertTrue(BonsplitConfiguration(preserveZoomOnNavigation: true).preserveZoomOnNavigation)
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
