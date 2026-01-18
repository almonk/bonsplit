import SwiftUI

/// Main container view that renders the entire split tree (internal implementation)
struct SplitViewContainer<Content: View, EmptyContent: View>: View {
    @Bindable var controller: SplitViewController
    let contentBuilder: (TabItem, PaneID) -> Content
    let emptyPaneBuilder: (PaneID) -> EmptyContent
    var showSplitButtons: Bool = true
    var contentViewLifecycle: ContentViewLifecycle = .recreateOnSwitch

    var body: some View {
        splitNodeContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focusable()
            .focusEffectDisabled()
    }

    @ViewBuilder
    private var splitNodeContent: some View {
        SplitNodeView(
            node: controller.rootNode,
            controller: controller,
            contentBuilder: contentBuilder,
            emptyPaneBuilder: emptyPaneBuilder,
            showSplitButtons: showSplitButtons,
            contentViewLifecycle: contentViewLifecycle
        )
    }
}
