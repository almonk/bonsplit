import Foundation
import SwiftUI

/// Controls how tab content views are managed when switching between tabs
public enum ContentViewLifecycle: Sendable {
    /// Only the selected tab's content view is rendered. Other tabs' views are
    /// destroyed and recreated when selected. This is memory efficient but loses
    /// view state like scroll position, @State variables, and focus.
    case recreateOnSwitch

    /// All tab content views are kept in the view hierarchy, with non-selected tabs
    /// hidden. This preserves all view state (scroll position, @State, focus, etc.)
    /// at the cost of higher memory usage.
    case keepAllAlive
}

/// Controls the position where new tabs are created
public enum NewTabPosition: Sendable {
    /// Insert the new tab after the currently focused tab,
    /// or at the end if there are no focused tabs.
    case current

    /// Insert the new tab at the end of the tab list.
    case end
}

/// Configuration for the split tab bar appearance and behavior
public struct BonsplitConfiguration: Sendable {

    // MARK: - Behavior

    /// Whether to allow creating splits
    public var allowSplits: Bool

    /// Whether to allow closing tabs
    public var allowCloseTabs: Bool

    /// Whether to allow closing the last pane
    public var allowCloseLastPane: Bool

    /// Whether to allow drag & drop reordering of tabs
    public var allowTabReordering: Bool

    /// Whether to allow moving tabs between panes
    public var allowCrossPaneTabMove: Bool

    /// Whether to automatically close empty panes
    public var autoCloseEmptyPanes: Bool

    /// Controls how tab content views are managed when switching tabs
    public var contentViewLifecycle: ContentViewLifecycle

    /// Controls where new tabs are inserted in the tab list
    public var newTabPosition: NewTabPosition

    // MARK: - Appearance

    /// Tab bar appearance customization
    public var appearance: Appearance

    // MARK: - Presets

    public static let `default` = BonsplitConfiguration()

    public static let singlePane = BonsplitConfiguration(
        allowSplits: false,
        allowCloseLastPane: false
    )

    public static let readOnly = BonsplitConfiguration(
        allowSplits: false,
        allowCloseTabs: false,
        allowTabReordering: false,
        allowCrossPaneTabMove: false
    )

    // MARK: - Initializer

    public init(
        allowSplits: Bool = true,
        allowCloseTabs: Bool = true,
        allowCloseLastPane: Bool = false,
        allowTabReordering: Bool = true,
        allowCrossPaneTabMove: Bool = true,
        autoCloseEmptyPanes: Bool = true,
        contentViewLifecycle: ContentViewLifecycle = .recreateOnSwitch,
        newTabPosition: NewTabPosition = .current,
        appearance: Appearance = .default
    ) {
        self.allowSplits = allowSplits
        self.allowCloseTabs = allowCloseTabs
        self.allowCloseLastPane = allowCloseLastPane
        self.allowTabReordering = allowTabReordering
        self.allowCrossPaneTabMove = allowCrossPaneTabMove
        self.autoCloseEmptyPanes = autoCloseEmptyPanes
        self.contentViewLifecycle = contentViewLifecycle
        self.newTabPosition = newTabPosition
        self.appearance = appearance
    }
}

// MARK: - Appearance Configuration

extension BonsplitConfiguration {
    public struct Appearance: Sendable {
        // MARK: - Tab Bar

        /// Height of the tab bar
        public var tabBarHeight: CGFloat

        // MARK: - Tabs

        /// Minimum width of a tab
        public var tabMinWidth: CGFloat

        /// Maximum width of a tab
        public var tabMaxWidth: CGFloat

        /// Spacing between tabs
        public var tabSpacing: CGFloat

        // MARK: - Split View

        /// Minimum width of a pane
        public var minimumPaneWidth: CGFloat

        /// Minimum height of a pane
        public var minimumPaneHeight: CGFloat

        /// Whether to show split buttons in the tab bar
        public var showSplitButtons: Bool

        // MARK: - Animations

        /// Duration of animations
        public var animationDuration: Double

        /// Whether to enable animations
        public var enableAnimations: Bool

        // MARK: - Presets

        public static let `default` = Appearance()

        public static let compact = Appearance(
            tabBarHeight: 28,
            tabMinWidth: 100,
            tabMaxWidth: 160
        )

        public static let spacious = Appearance(
            tabBarHeight: 38,
            tabMinWidth: 160,
            tabMaxWidth: 280,
            tabSpacing: 2
        )

        // MARK: - Initializer

        public init(
            tabBarHeight: CGFloat = 33,
            tabMinWidth: CGFloat = 140,
            tabMaxWidth: CGFloat = 220,
            tabSpacing: CGFloat = 0,
            minimumPaneWidth: CGFloat = 100,
            minimumPaneHeight: CGFloat = 100,
            showSplitButtons: Bool = true,
            animationDuration: Double = 0.15,
            enableAnimations: Bool = true
        ) {
            self.tabBarHeight = tabBarHeight
            self.tabMinWidth = tabMinWidth
            self.tabMaxWidth = tabMaxWidth
            self.tabSpacing = tabSpacing
            self.minimumPaneWidth = minimumPaneWidth
            self.minimumPaneHeight = minimumPaneHeight
            self.showSplitButtons = showSplitButtons
            self.animationDuration = animationDuration
            self.enableAnimations = enableAnimations
        }
    }
}
