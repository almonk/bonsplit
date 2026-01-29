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
        return closeTab(tabId, with: tabIndex, in: pane)
    }
    
    /// Close a tab by ID in a specific pane.
    /// - Parameter tabId: The tab to close
    /// - Parameter paneId: The pane in which to close the tab
    public func closeTab(_ tabId: TabID, inPane paneId: PaneID) -> Bool {
        guard let pane = internalController.rootNode.findPane(paneId),
              let tabIndex = pane.tabs.firstIndex(where: { $0.id == tabId.id }) else {
            return false
        }
        
        return closeTab(tabId, with: tabIndex, in: pane)
    }
    
    /// Internal helper to close a tab given its index in a pane
    /// - Parameter tabId: The tab to close
    /// - Parameter tabIndex: The position of the tab within the pane
    /// - Parameter pane: The pane in which to close the tab
    private func closeTab(_ tabId: TabID, with tabIndex: Int, in pane: PaneState) -> Bool {
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

        // Notify geometry change after a brief delay to allow layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notifyGeometryChange()
        }

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

        // Notify geometry change after a brief delay to allow layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notifyGeometryChange()
        }

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

    // MARK: - Geometry Query API

    /// Get current layout snapshot with pixel coordinates
    public func layoutSnapshot() -> LayoutSnapshot {
        let containerFrame = internalController.containerFrame
        let paneBounds = internalController.rootNode.computePaneBounds()

        let paneGeometries = paneBounds.map { bounds -> PaneGeometry in
            let pane = internalController.rootNode.findPane(bounds.paneId)
            let pixelFrame = PixelRect(
                x: Double(bounds.bounds.minX * containerFrame.width + containerFrame.origin.x),
                y: Double(bounds.bounds.minY * containerFrame.height + containerFrame.origin.y),
                width: Double(bounds.bounds.width * containerFrame.width),
                height: Double(bounds.bounds.height * containerFrame.height)
            )
            return PaneGeometry(
                paneId: bounds.paneId.id.uuidString,
                frame: pixelFrame,
                selectedTabId: pane?.selectedTabId?.uuidString,
                tabIds: pane?.tabs.map { $0.id.uuidString } ?? []
            )
        }

        return LayoutSnapshot(
            containerFrame: PixelRect(from: containerFrame),
            panes: paneGeometries,
            focusedPaneId: focusedPaneId?.id.uuidString,
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// Get full tree structure for external consumption
    public func treeSnapshot() -> ExternalTreeNode {
        let containerFrame = internalController.containerFrame
        return buildExternalTree(from: internalController.rootNode, containerFrame: containerFrame)
    }

    private func buildExternalTree(from node: SplitNode, containerFrame: CGRect, bounds: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> ExternalTreeNode {
        switch node {
        case .pane(let paneState):
            let pixelFrame = PixelRect(
                x: Double(bounds.minX * containerFrame.width + containerFrame.origin.x),
                y: Double(bounds.minY * containerFrame.height + containerFrame.origin.y),
                width: Double(bounds.width * containerFrame.width),
                height: Double(bounds.height * containerFrame.height)
            )
            let tabs = paneState.tabs.map { ExternalTab(id: $0.id.uuidString, title: $0.title) }
            let paneNode = ExternalPaneNode(
                id: paneState.id.id.uuidString,
                frame: pixelFrame,
                tabs: tabs,
                selectedTabId: paneState.selectedTabId?.uuidString
            )
            return .pane(paneNode)

        case .split(let splitState):
            let dividerPos = splitState.dividerPosition
            let firstBounds: CGRect
            let secondBounds: CGRect

            switch splitState.orientation {
            case .horizontal:
                firstBounds = CGRect(x: bounds.minX, y: bounds.minY,
                                     width: bounds.width * dividerPos, height: bounds.height)
                secondBounds = CGRect(x: bounds.minX + bounds.width * dividerPos, y: bounds.minY,
                                      width: bounds.width * (1 - dividerPos), height: bounds.height)
            case .vertical:
                firstBounds = CGRect(x: bounds.minX, y: bounds.minY,
                                     width: bounds.width, height: bounds.height * dividerPos)
                secondBounds = CGRect(x: bounds.minX, y: bounds.minY + bounds.height * dividerPos,
                                      width: bounds.width, height: bounds.height * (1 - dividerPos))
            }

            let splitNode = ExternalSplitNode(
                id: splitState.id.uuidString,
                orientation: splitState.orientation == .horizontal ? "horizontal" : "vertical",
                dividerPosition: Double(splitState.dividerPosition),
                first: buildExternalTree(from: splitState.first, containerFrame: containerFrame, bounds: firstBounds),
                second: buildExternalTree(from: splitState.second, containerFrame: containerFrame, bounds: secondBounds)
            )
            return .split(splitNode)
        }
    }

    /// Check if a split exists by ID
    public func findSplit(_ splitId: UUID) -> Bool {
        return internalController.findSplit(splitId) != nil
    }

    // MARK: - Geometry Update API

    /// Set divider position for a split node (0.0-1.0)
    /// - Parameters:
    ///   - position: The new divider position (clamped to 0.1-0.9)
    ///   - splitId: The UUID of the split to update
    ///   - fromExternal: Set to true to suppress outgoing notifications (prevents loops)
    /// - Returns: true if the split was found and updated
    @discardableResult
    public func setDividerPosition(_ position: CGFloat, forSplit splitId: UUID, fromExternal: Bool = false) -> Bool {
        guard let split = internalController.findSplit(splitId) else { return false }

        if fromExternal {
            internalController.isExternalUpdateInProgress = true
        }

        // Clamp position to valid range
        let clampedPosition = min(max(position, 0.1), 0.9)
        split.dividerPosition = clampedPosition

        if fromExternal {
            // Use a slight delay to allow the UI to update before re-enabling notifications
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.internalController.isExternalUpdateInProgress = false
            }
        }

        return true
    }

    /// Update container frame (called when window moves/resizes)
    public func setContainerFrame(_ frame: CGRect) {
        internalController.containerFrame = frame
    }

    /// Notify geometry change to delegate (internal use)
    /// - Parameter isDragging: Whether the change is due to active divider dragging
    internal func notifyGeometryChange(isDragging: Bool = false) {
        guard !internalController.isExternalUpdateInProgress else { return }

        // If dragging, check if delegate wants notifications during drag
        if isDragging {
            let shouldNotify = delegate?.splitTabBar(self, shouldNotifyDuringDrag: true) ?? false
            guard shouldNotify else { return }
        }

        // Debounce: skip if less than 50ms since last notification
        let now = Date().timeIntervalSince1970
        let debounceInterval: TimeInterval = 0.05
        guard now - internalController.lastGeometryNotificationTime >= debounceInterval else { return }

        internalController.lastGeometryNotificationTime = now

        let snapshot = layoutSnapshot()
        delegate?.splitTabBar(self, didChangeGeometry: snapshot)
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
