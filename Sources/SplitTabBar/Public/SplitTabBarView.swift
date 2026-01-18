import SwiftUI

/// Main entry point for the SplitTabBar library
///
/// Usage:
/// ```swift
/// struct MyApp: View {
///     @State private var controller = SplitTabBarController()
///
///     var body: some View {
///         SplitTabBarView(controller: controller) { tab, paneId in
///             MyContentView(for: tab)
///                 .onTapGesture { controller.focusPane(paneId) }
///         } emptyPane: { paneId in
///             Text("Empty pane")
///         }
///     }
/// }
/// ```
public struct SplitTabBarView<Content: View, EmptyContent: View>: View {
    @Bindable private var controller: SplitTabBarController
    private let contentBuilder: (Tab, PaneID) -> Content
    private let emptyPaneBuilder: (PaneID) -> EmptyContent

    /// Initialize with a controller, content builder, and empty pane builder
    /// - Parameters:
    ///   - controller: The SplitTabBarController managing the tab state
    ///   - content: A ViewBuilder closure that provides content for each tab. Receives the tab and pane ID.
    ///   - emptyPane: A ViewBuilder closure that provides content for empty panes
    public init(
        controller: SplitTabBarController,
        @ViewBuilder content: @escaping (Tab, PaneID) -> Content,
        @ViewBuilder emptyPane: @escaping (PaneID) -> EmptyContent
    ) {
        self.controller = controller
        self.contentBuilder = content
        self.emptyPaneBuilder = emptyPane
    }

    public var body: some View {
        SplitViewContainer(
            controller: controller.internalController,
            contentBuilder: { tabItem, paneId in
                contentBuilder(Tab(from: tabItem), PaneID(id: paneId.id))
            },
            emptyPaneBuilder: { internalPaneId in
                emptyPaneBuilder(PaneID(id: internalPaneId.id))
            },
            showSplitButtons: controller.configuration.allowSplits && controller.configuration.appearance.showSplitButtons,
            contentViewLifecycle: controller.configuration.contentViewLifecycle
        )
    }
}

// MARK: - Convenience initializer with default empty view

extension SplitTabBarView where EmptyContent == DefaultEmptyPaneView {
    /// Initialize with a controller and content builder, using the default empty pane view
    /// - Parameters:
    ///   - controller: The SplitTabBarController managing the tab state
    ///   - content: A ViewBuilder closure that provides content for each tab. Receives the tab and pane ID.
    public init(
        controller: SplitTabBarController,
        @ViewBuilder content: @escaping (Tab, PaneID) -> Content
    ) {
        self.controller = controller
        self.contentBuilder = content
        self.emptyPaneBuilder = { _ in DefaultEmptyPaneView() }
    }
}

/// Default view shown when a pane has no tabs
public struct DefaultEmptyPaneView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Open Tabs")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
