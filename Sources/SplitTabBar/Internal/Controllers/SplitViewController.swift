import Foundation
import SwiftUI

/// Central controller managing the entire split view state (internal implementation)
@Observable
@MainActor
final class SplitViewController {
    /// The root node of the split tree
    var rootNode: SplitNode

    /// Currently focused pane ID
    var focusedPaneId: PaneID?

    /// Tab currently being dragged (for visual feedback)
    var draggingTab: TabItem?

    /// Source pane of the dragging tab
    var dragSourcePaneId: PaneID?

    init(rootNode: SplitNode? = nil) {
        if let rootNode {
            self.rootNode = rootNode
        } else {
            // Initialize with a single pane containing a welcome tab
            let welcomeTab = TabItem(title: "Welcome", icon: "star")
            let initialPane = PaneState(tabs: [welcomeTab])
            self.rootNode = .pane(initialPane)
            self.focusedPaneId = initialPane.id
        }
    }

    // MARK: - Focus Management

    /// Set focus to a specific pane
    func focusPane(_ paneId: PaneID) {
        guard rootNode.findPane(paneId) != nil else { return }
        focusedPaneId = paneId
    }

    /// Get the currently focused pane state
    var focusedPane: PaneState? {
        guard let focusedPaneId else { return nil }
        return rootNode.findPane(focusedPaneId)
    }

    // MARK: - Split Operations

    /// Split the specified pane in the given orientation
    func splitPane(_ paneId: PaneID, orientation: SplitOrientation, with newTab: TabItem? = nil) {
        rootNode = splitNodeRecursively(
            node: rootNode,
            targetPaneId: paneId,
            orientation: orientation,
            newTab: newTab
        )
    }

    private func splitNodeRecursively(
        node: SplitNode,
        targetPaneId: PaneID,
        orientation: SplitOrientation,
        newTab: TabItem?
    ) -> SplitNode {
        switch node {
        case .pane(let paneState):
            if paneState.id == targetPaneId {
                // Create new pane - empty if no tab provided (gives developer full control)
                let newPane: PaneState
                if let tab = newTab {
                    newPane = PaneState(tabs: [tab])
                } else {
                    newPane = PaneState(tabs: [])
                }

                // Start with divider at the edge so there's no flash before animation
                let splitState = SplitState(
                    orientation: orientation,
                    first: .pane(paneState),
                    second: .pane(newPane),
                    dividerPosition: 1.0,  // Start at edge (will animate to 0.5)
                    animationOrigin: .fromSecond  // New pane slides in from right/bottom
                )

                // Focus the new pane
                focusedPaneId = newPane.id

                return .split(splitState)
            }
            return node

        case .split(let splitState):
            splitState.first = splitNodeRecursively(
                node: splitState.first,
                targetPaneId: targetPaneId,
                orientation: orientation,
                newTab: newTab
            )
            splitState.second = splitNodeRecursively(
                node: splitState.second,
                targetPaneId: targetPaneId,
                orientation: orientation,
                newTab: newTab
            )
            return .split(splitState)
        }
    }

    /// Split a pane with a specific tab, optionally inserting the new pane first
    func splitPaneWithTab(_ paneId: PaneID, orientation: SplitOrientation, tab: TabItem, insertFirst: Bool) {
        rootNode = splitNodeWithTabRecursively(
            node: rootNode,
            targetPaneId: paneId,
            orientation: orientation,
            tab: tab,
            insertFirst: insertFirst
        )
    }

    private func splitNodeWithTabRecursively(
        node: SplitNode,
        targetPaneId: PaneID,
        orientation: SplitOrientation,
        tab: TabItem,
        insertFirst: Bool
    ) -> SplitNode {
        switch node {
        case .pane(let paneState):
            if paneState.id == targetPaneId {
                // Create new pane with the tab
                let newPane = PaneState(tabs: [tab])

                // Start with divider at the edge so there's no flash before animation
                let splitState: SplitState
                if insertFirst {
                    // New pane goes first (left or top) - starts at 0, animates to 0.5
                    splitState = SplitState(
                        orientation: orientation,
                        first: .pane(newPane),
                        second: .pane(paneState),
                        dividerPosition: 0.0,
                        animationOrigin: .fromFirst
                    )
                } else {
                    // New pane goes second (right or bottom) - starts at 1, animates to 0.5
                    splitState = SplitState(
                        orientation: orientation,
                        first: .pane(paneState),
                        second: .pane(newPane),
                        dividerPosition: 1.0,
                        animationOrigin: .fromSecond
                    )
                }

                // Focus the new pane
                focusedPaneId = newPane.id

                return .split(splitState)
            }
            return node

        case .split(let splitState):
            splitState.first = splitNodeWithTabRecursively(
                node: splitState.first,
                targetPaneId: targetPaneId,
                orientation: orientation,
                tab: tab,
                insertFirst: insertFirst
            )
            splitState.second = splitNodeWithTabRecursively(
                node: splitState.second,
                targetPaneId: targetPaneId,
                orientation: orientation,
                tab: tab,
                insertFirst: insertFirst
            )
            return .split(splitState)
        }
    }

    /// Close a pane and collapse the split
    func closePane(_ paneId: PaneID) {
        // Don't close the last pane
        guard rootNode.allPaneIds.count > 1 else { return }

        let (newRoot, siblingPaneId) = closePaneRecursively(node: rootNode, targetPaneId: paneId)

        if let newRoot {
            rootNode = newRoot
        }

        // Focus the sibling or first available pane
        if let siblingPaneId {
            focusedPaneId = siblingPaneId
        } else if let firstPane = rootNode.allPaneIds.first {
            focusedPaneId = firstPane
        }
    }

    private func closePaneRecursively(
        node: SplitNode,
        targetPaneId: PaneID
    ) -> (SplitNode?, PaneID?) {
        switch node {
        case .pane(let paneState):
            if paneState.id == targetPaneId {
                return (nil, nil)
            }
            return (node, nil)

        case .split(let splitState):
            // Check if either direct child is the target
            if case .pane(let firstPane) = splitState.first, firstPane.id == targetPaneId {
                let focusTarget = splitState.second.allPaneIds.first
                return (splitState.second, focusTarget)
            }

            if case .pane(let secondPane) = splitState.second, secondPane.id == targetPaneId {
                let focusTarget = splitState.first.allPaneIds.first
                return (splitState.first, focusTarget)
            }

            // Recursively check children
            let (newFirst, focusFromFirst) = closePaneRecursively(node: splitState.first, targetPaneId: targetPaneId)
            if newFirst == nil {
                return (splitState.second, splitState.second.allPaneIds.first)
            }

            let (newSecond, focusFromSecond) = closePaneRecursively(node: splitState.second, targetPaneId: targetPaneId)
            if newSecond == nil {
                return (splitState.first, splitState.first.allPaneIds.first)
            }

            if let newFirst { splitState.first = newFirst }
            if let newSecond { splitState.second = newSecond }

            return (.split(splitState), focusFromFirst ?? focusFromSecond)
        }
    }

    // MARK: - Tab Operations

    /// Add a tab to the focused pane (or specified pane)
    func addTab(_ tab: TabItem, toPane paneId: PaneID? = nil) {
        let targetPaneId = paneId ?? focusedPaneId
        guard let targetPaneId,
              let pane = rootNode.findPane(targetPaneId) else { return }

        pane.addTab(tab)
    }

    /// Move a tab from one pane to another
    func moveTab(_ tab: TabItem, from sourcePaneId: PaneID, to targetPaneId: PaneID, atIndex index: Int? = nil) {
        guard let sourcePane = rootNode.findPane(sourcePaneId),
              let targetPane = rootNode.findPane(targetPaneId) else { return }

        // Remove from source
        sourcePane.removeTab(tab.id)

        // Add to target
        if let index {
            targetPane.insertTab(tab, at: index)
        } else {
            targetPane.addTab(tab)
        }

        // Focus target pane
        focusPane(targetPaneId)

        // If source pane is now empty and not the only pane, close it
        if sourcePane.tabs.isEmpty && rootNode.allPaneIds.count > 1 {
            closePane(sourcePaneId)
        }
    }

    /// Close a tab in a specific pane
    func closeTab(_ tabId: UUID, inPane paneId: PaneID) {
        guard let pane = rootNode.findPane(paneId) else { return }

        pane.removeTab(tabId)

        // If pane is now empty and not the only pane, close it
        if pane.tabs.isEmpty && rootNode.allPaneIds.count > 1 {
            closePane(paneId)
        }
    }

    // MARK: - Keyboard Navigation

    /// Navigate focus to an adjacent pane based on spatial position
    func navigateFocus(direction: NavigationDirection) {
        guard let currentPaneId = focusedPaneId else { return }

        let allPaneBounds = rootNode.computePaneBounds()
        guard let currentBounds = allPaneBounds.first(where: { $0.paneId == currentPaneId })?.bounds else { return }

        if let targetPaneId = findBestNeighbor(from: currentBounds, currentPaneId: currentPaneId,
                                               direction: direction, allPaneBounds: allPaneBounds) {
            focusPane(targetPaneId)
        }
        // No neighbor found = at edge, do nothing
    }

    private func findBestNeighbor(from currentBounds: CGRect, currentPaneId: PaneID,
                                  direction: NavigationDirection, allPaneBounds: [PaneBounds]) -> PaneID? {
        let epsilon: CGFloat = 0.001

        // Filter to panes in the target direction
        let candidates = allPaneBounds.filter { paneBounds in
            guard paneBounds.paneId != currentPaneId else { return false }
            let b = paneBounds.bounds
            switch direction {
            case .left:  return b.maxX <= currentBounds.minX + epsilon
            case .right: return b.minX >= currentBounds.maxX - epsilon
            case .up:    return b.maxY <= currentBounds.minY + epsilon
            case .down:  return b.minY >= currentBounds.maxY - epsilon
            }
        }

        guard !candidates.isEmpty else { return nil }

        // Score by overlap (perpendicular axis) and distance
        let scored: [(PaneID, CGFloat, CGFloat)] = candidates.map { c in
            let overlap: CGFloat
            let distance: CGFloat

            switch direction {
            case .left, .right:
                // Vertical overlap for horizontal movement
                overlap = max(0, min(currentBounds.maxY, c.bounds.maxY) - max(currentBounds.minY, c.bounds.minY))
                distance = direction == .left ? (currentBounds.minX - c.bounds.maxX) : (c.bounds.minX - currentBounds.maxX)
            case .up, .down:
                // Horizontal overlap for vertical movement
                overlap = max(0, min(currentBounds.maxX, c.bounds.maxX) - max(currentBounds.minX, c.bounds.minX))
                distance = direction == .up ? (currentBounds.minY - c.bounds.maxY) : (c.bounds.minY - currentBounds.maxY)
            }

            return (c.paneId, overlap, distance)
        }

        // Sort: prefer more overlap, then closer distance
        let sorted = scored.sorted { a, b in
            if abs(a.1 - b.1) > epsilon { return a.1 > b.1 }
            return a.2 < b.2
        }

        return sorted.first?.0
    }

    /// Create a new tab in the focused pane
    func createNewTab() {
        guard let pane = focusedPane else { return }
        let count = pane.tabs.count + 1
        let newTab = TabItem(title: "Untitled \(count)", icon: "doc")
        pane.addTab(newTab)
    }

    /// Close the currently selected tab in the focused pane
    func closeSelectedTab() {
        guard let pane = focusedPane,
              let selectedTabId = pane.selectedTabId else { return }
        closeTab(selectedTabId, inPane: pane.id)
    }

    /// Select the previous tab in the focused pane
    func selectPreviousTab() {
        guard let pane = focusedPane,
              let selectedTabId = pane.selectedTabId,
              let currentIndex = pane.tabs.firstIndex(where: { $0.id == selectedTabId }),
              !pane.tabs.isEmpty else { return }

        let newIndex = currentIndex > 0 ? currentIndex - 1 : pane.tabs.count - 1
        pane.selectTab(pane.tabs[newIndex].id)
    }

    /// Select the next tab in the focused pane
    func selectNextTab() {
        guard let pane = focusedPane,
              let selectedTabId = pane.selectedTabId,
              let currentIndex = pane.tabs.firstIndex(where: { $0.id == selectedTabId }),
              !pane.tabs.isEmpty else { return }

        let newIndex = currentIndex < pane.tabs.count - 1 ? currentIndex + 1 : 0
        pane.selectTab(pane.tabs[newIndex].id)
    }
}
