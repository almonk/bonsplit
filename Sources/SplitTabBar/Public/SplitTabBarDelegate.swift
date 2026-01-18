import Foundation

/// Protocol for receiving callbacks about tab bar events
public protocol SplitTabBarDelegate: AnyObject {
    // MARK: - Tab Lifecycle (Veto Operations)

    /// Called when a new tab is about to be created.
    /// Return `false` to prevent creation.
    func splitTabBar(_ controller: SplitTabBarController, shouldCreateTab tab: Tab, inPane pane: PaneID) -> Bool

    /// Called when a tab is about to be closed.
    /// Return `false` to prevent closing (e.g., prompt to save unsaved changes).
    func splitTabBar(_ controller: SplitTabBarController, shouldCloseTab tab: Tab, inPane pane: PaneID) -> Bool

    // MARK: - Tab Lifecycle (Notifications)

    /// Called after a tab has been created.
    func splitTabBar(_ controller: SplitTabBarController, didCreateTab tab: Tab, inPane pane: PaneID)

    /// Called after a tab has been closed.
    func splitTabBar(_ controller: SplitTabBarController, didCloseTab tabId: TabID, fromPane pane: PaneID)

    /// Called when a tab is selected.
    func splitTabBar(_ controller: SplitTabBarController, didSelectTab tab: Tab, inPane pane: PaneID)

    /// Called when a tab is moved between panes.
    func splitTabBar(_ controller: SplitTabBarController, didMoveTab tab: Tab, fromPane source: PaneID, toPane destination: PaneID)

    // MARK: - Split Lifecycle (Veto Operations)

    /// Called when a split is about to be created.
    /// Return `false` to prevent the split.
    func splitTabBar(_ controller: SplitTabBarController, shouldSplitPane pane: PaneID, orientation: SplitOrientation) -> Bool

    /// Called when a pane is about to be closed.
    /// Return `false` to prevent closing.
    func splitTabBar(_ controller: SplitTabBarController, shouldClosePane pane: PaneID) -> Bool

    // MARK: - Split Lifecycle (Notifications)

    /// Called after a split has been created.
    func splitTabBar(_ controller: SplitTabBarController, didSplitPane originalPane: PaneID, newPane: PaneID, orientation: SplitOrientation)

    /// Called after a pane has been closed.
    func splitTabBar(_ controller: SplitTabBarController, didClosePane paneId: PaneID)

    // MARK: - Focus

    /// Called when focus changes to a different pane.
    func splitTabBar(_ controller: SplitTabBarController, didFocusPane pane: PaneID)
}

// MARK: - Default Implementations (all methods optional)

public extension SplitTabBarDelegate {
    func splitTabBar(_ controller: SplitTabBarController, shouldCreateTab tab: Tab, inPane pane: PaneID) -> Bool { true }
    func splitTabBar(_ controller: SplitTabBarController, shouldCloseTab tab: Tab, inPane pane: PaneID) -> Bool { true }
    func splitTabBar(_ controller: SplitTabBarController, didCreateTab tab: Tab, inPane pane: PaneID) {}
    func splitTabBar(_ controller: SplitTabBarController, didCloseTab tabId: TabID, fromPane pane: PaneID) {}
    func splitTabBar(_ controller: SplitTabBarController, didSelectTab tab: Tab, inPane pane: PaneID) {}
    func splitTabBar(_ controller: SplitTabBarController, didMoveTab tab: Tab, fromPane source: PaneID, toPane destination: PaneID) {}
    func splitTabBar(_ controller: SplitTabBarController, shouldSplitPane pane: PaneID, orientation: SplitOrientation) -> Bool { true }
    func splitTabBar(_ controller: SplitTabBarController, shouldClosePane pane: PaneID) -> Bool { true }
    func splitTabBar(_ controller: SplitTabBarController, didSplitPane originalPane: PaneID, newPane: PaneID, orientation: SplitOrientation) {}
    func splitTabBar(_ controller: SplitTabBarController, didClosePane paneId: PaneID) {}
    func splitTabBar(_ controller: SplitTabBarController, didFocusPane pane: PaneID) {}
}
