import Foundation
import SwiftUI

/// State for a single pane (leaf node in the split tree)
@Observable
final class PaneState: Identifiable {
    let id: PaneID
    var tabs: [TabItem]
    var selectedTabId: UUID?

    init(
        id: PaneID = PaneID(),
        tabs: [TabItem] = [],
        selectedTabId: UUID? = nil
    ) {
        self.id = id
        self.tabs = tabs
        self.selectedTabId = selectedTabId ?? tabs.first?.id
    }

    /// Currently selected tab
    var selectedTab: TabItem? {
        tabs.first { $0.id == selectedTabId }
    }

    /// Select a tab by ID
    func selectTab(_ tabId: UUID) {
        guard tabs.contains(where: { $0.id == tabId }) else { return }
        selectedTabId = tabId
    }

    /// Add a new tab
    func addTab(_ tab: TabItem, select: Bool = true) {
        tabs.append(tab)
        if select {
            selectedTabId = tab.id
        }
    }

    /// Insert a tab at a specific index
    func insertTab(_ tab: TabItem, at index: Int, select: Bool = true) {
        let safeIndex = min(max(0, index), tabs.count)
        tabs.insert(tab, at: safeIndex)
        if select {
            selectedTabId = tab.id
        }
    }

    /// Remove a tab and return it
    @discardableResult
    func removeTab(_ tabId: UUID) -> TabItem? {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return nil }
        let tab = tabs.remove(at: index)

        // If we removed the selected tab, select an adjacent one
        if selectedTabId == tabId {
            if index > 0 {
                selectedTabId = tabs[index - 1].id
            } else if !tabs.isEmpty {
                selectedTabId = tabs[0].id
            } else {
                selectedTabId = nil
            }
        }

        return tab
    }

    /// Move a tab within this pane
    func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              tabs.indices.contains(sourceIndex),
              destinationIndex >= 0, destinationIndex <= tabs.count else { return }

        let tab = tabs.remove(at: sourceIndex)
        let adjustedIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        tabs.insert(tab, at: adjustedIndex)
    }
}

extension PaneState: Equatable {
    static func == (lhs: PaneState, rhs: PaneState) -> Bool {
        lhs.id == rhs.id
    }
}
