import Foundation
import SwiftUI

/// Main controller for the split tab bar system
@MainActor
@Observable
public final class BonsplitController {

    // MARK: - Delegate

    /// Delegate for receiving callbacks about tab bar events
    public weak var delegate: BonsplitDelegate?

    // MARK: - Configuration

    /// Configuration for behavior and appearance
    public var configuration: BonsplitConfiguration

    // MARK: - Internal State

    internal var internalController: SplitViewController

    // MARK: - Initialization

    /// Create a new controller with the specified configuration
    public init(configuration: BonsplitConfiguration = .default) {
        self.configuration = configuration
        self.internalController = SplitViewController()
    }

    // MARK: - Tab Operations

    /// Create a new tab in the focused pane (or specified pane)
    /// - Parameters:
    ///   - title: The tab title
    ///   - icon: Optional SF Symbol name for the tab icon
    ///   - isDirty: Whether the tab shows a dirty indicator
    ///   - pane: Optional pane to add the tab to (defaults to focused pane)
    /// - Returns: The TabID of the created tab, or nil if creation was vetoed by delegate
    @discardableResult
    public func createTab(
        title: String,
        icon: String? = "doc.text",
        isDirty: Bool = false,
        inPane pane: PaneID? = nil
    ) -> TabID? {
        let tabId = TabID()
        let tab = Tab(id: tabId, title: title, icon: icon, isDirty: isDirty)
        let targetPane = pane ?? focusedPaneId ?? PaneID(id: internalController.rootNode.allPaneIds.first!.id)

        // Check with delegate
        if delegate?.splitTabBar(self, shouldCreateTab: tab, inPane: targetPane) == false {
            return nil
        }

        // Calculate insertion index based on configuration
        let insertIndex: Int?
        switch configuration.newTabPosition {
        case .current:
            // Insert after the currently selected tab
            if let paneState = internalController.rootNode.findPane(PaneID(id: targetPane.id)),
               let selectedTabId = paneState.selectedTabId,
               let currentIndex = paneState.tabs.firstIndex(where: { $0.id == selectedTabId }) {
                insertIndex = currentIndex + 1
            } else {
                // No selected tab, append to end
                insertIndex = nil
            }
        case .end:
            insertIndex = nil
        }

        // Create internal TabItem
        let tabItem = TabItem(id: tabId.id, title: title, icon: icon, isDirty: isDirty)
        internalController.addTab(tabItem, toPane: PaneID(id: targetPane.id), atIndex: insertIndex)

        // Notify delegate
        delegate?.splitTabBar(self, didCreateTab: tab, inPane: targetPane)

        return tabId
    }

    /// Update an existing tab's metadata
    /// - Parameters:
    ///   - tabId: The tab to update
    ///   - title: New title (pass nil to keep current)
    ///   - icon: New icon (pass nil to keep current, pass .some(nil) to remove icon)
    ///   - isDirty: New dirty state (pass nil to keep current)
    public func updateTab(
        _ tabId: TabID,
        title: String? = nil,
        icon: String?? = nil,
        isDirty: Bool? = nil
    ) {
        guard let (pane, tabIndex) = findTabInternal(tabId) else { return }

        if let title = title {
            pane.tabs[tabIndex].title = title
        }
        if let icon = icon {
            pane.tabs[tabIndex].icon = icon
        }
        if let isDirty = isDirty {
            pane.tabs[tabIndex].isDirty = isDirty
        }
    }

    /// Close a tab by ID
    /// - Parameter tabId: The tab to close
    /// - Returns: true if the tab was closed, false if vetoed by delegate
    @discardableResult
    public func closeTab(_ tabId: TabID) -> Bool {
        guard let (pane, tabIndex) = findTabInternal(tabId) else { return false }

        let tabItem = pane.tabs[tabIndex]
        let tab = Tab(from: tabItem)
        let paneId = pane.id

        // Check with delegate
        if delegate?.splitTabBar(self, shouldCloseTab: tab, inPane: paneId) == false {
            return false
        }

        internalController.closeTab(tabId.id, inPane: pane.id)

        // Notify delegate
        delegate?.splitTabBar(self, didCloseTab: tabId, fromPane: paneId)

        return true
    }

    /// Select a tab by ID
    /// - Parameter tabId: The tab to select
    public func selectTab(_ tabId: TabID) {
        guard let (pane, tabIndex) = findTabInternal(tabId) else { return }

        pane.selectTab(tabId.id)
        internalController.focusPane(pane.id)

        // Notify delegate
        let tab = Tab(from: pane.tabs[tabIndex])
        delegate?.splitTabBar(self, didSelectTab: tab, inPane: pane.id)
    }

    /// Move to previous tab in focused pane
    public func selectPreviousTab() {
        internalController.selectPreviousTab()
        notifyTabSelection()
    }

    /// Move to next tab in focused pane
    public func selectNextTab() {
        internalController.selectNextTab()
        notifyTabSelection()
    }

    // MARK: - Split Operations

    /// Split the focused pane (or specified pane)
    /// - Parameters:
    ///   - paneId: Optional pane to split (defaults to focused pane)
    ///   - orientation: Direction to split (horizontal = side-by-side, vertical = stacked)
    ///   - tab: Optional tab to add to the new pane
    /// - Returns: The new pane ID, or nil if vetoed by delegate
    @discardableResult
    public func splitPane(
        _ paneId: PaneID? = nil,
        orientation: SplitOrientation,
        withTab tab: Tab? = nil
    ) -> PaneID? {
        guard configuration.allowSplits else { return nil }

        let targetPaneId = paneId ?? focusedPaneId
        guard let targetPaneId else { return nil }

        // Check with delegate
        if delegate?.splitTabBar(self, shouldSplitPane: targetPaneId, orientation: orientation) == false {
            return nil
        }

        let internalTab: TabItem?
        if let tab {
            internalTab = TabItem(id: tab.id.id, title: tab.title, icon: tab.icon, isDirty: tab.isDirty)
        } else {
            internalTab = nil
        }

        // Perform split
        internalController.splitPane(
            PaneID(id: targetPaneId.id),
            orientation: orientation,
            with: internalTab
        )

        // Find new pane (will be focused after split)
        let newPaneId = focusedPaneId!

        // Notify delegate
        delegate?.splitTabBar(self, didSplitPane: targetPaneId, newPane: newPaneId, orientation: orientation)

        return newPaneId
    }

    /// Close a specific pane
    /// - Parameter paneId: The pane to close
    /// - Returns: true if the pane was closed, false if vetoed by delegate
    @discardableResult
    public func closePane(_ paneId: PaneID) -> Bool {
        // Don't close if it's the last pane and not allowed
        if !configuration.allowCloseLastPane && internalController.rootNode.allPaneIds.count <= 1 {
            return false
        }

        // Check with delegate
        if delegate?.splitTabBar(self, shouldClosePane: paneId) == false {
            return false
        }

        internalController.closePane(PaneID(id: paneId.id))

        // Notify delegate
        delegate?.splitTabBar(self, didClosePane: paneId)

        return true
    }

    // MARK: - Focus Management

    /// Currently focused pane ID
    public var focusedPaneId: PaneID? {
        guard let internalId = internalController.focusedPaneId else { return nil }
        return internalId
    }

    /// Focus a specific pane
    public func focusPane(_ paneId: PaneID) {
        internalController.focusPane(PaneID(id: paneId.id))
        delegate?.splitTabBar(self, didFocusPane: paneId)
    }

    /// Navigate focus in a direction
    public func navigateFocus(direction: NavigationDirection) {
        internalController.navigateFocus(direction: direction)
        if let focusedPaneId {
            delegate?.splitTabBar(self, didFocusPane: focusedPaneId)
        }
    }

    // MARK: - Query Methods

    /// Get all tab IDs
    public var allTabIds: [TabID] {
        internalController.rootNode.allPanes.flatMap { pane in
            pane.tabs.map { TabID(id: $0.id) }
        }
    }

    /// Get all pane IDs
    public var allPaneIds: [PaneID] {
        internalController.rootNode.allPaneIds
    }

    /// Get tab metadata by ID
    public func tab(_ tabId: TabID) -> Tab? {
        guard let (pane, tabIndex) = findTabInternal(tabId) else { return nil }
        return Tab(from: pane.tabs[tabIndex])
    }

    /// Get tabs in a specific pane
    public func tabs(inPane paneId: PaneID) -> [Tab] {
        guard let pane = internalController.rootNode.findPane(PaneID(id: paneId.id)) else {
            return []
        }
        return pane.tabs.map { Tab(from: $0) }
    }

    /// Get selected tab in a pane
    public func selectedTab(inPane paneId: PaneID) -> Tab? {
        guard let pane = internalController.rootNode.findPane(PaneID(id: paneId.id)),
              let selected = pane.selectedTab else {
            return nil
        }
        return Tab(from: selected)
    }

    // MARK: - Private Helpers

    private func findTabInternal(_ tabId: TabID) -> (PaneState, Int)? {
        for pane in internalController.rootNode.allPanes {
            if let index = pane.tabs.firstIndex(where: { $0.id == tabId.id }) {
                return (pane, index)
            }
        }
        return nil
    }

    private func notifyTabSelection() {
        guard let pane = internalController.focusedPane,
              let tabItem = pane.selectedTab else { return }
        let tab = Tab(from: tabItem)
        delegate?.splitTabBar(self, didSelectTab: tab, inPane: pane.id)
    }
}
