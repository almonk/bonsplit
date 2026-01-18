import SwiftUI
import AppKit

/// SwiftUI wrapper around NSSplitView for native split behavior
struct SplitContainerView<Content: View, EmptyContent: View>: NSViewRepresentable {
    @Bindable var splitState: SplitState
    let controller: SplitViewController
    let contentBuilder: (TabItem, PaneID) -> Content
    let emptyPaneBuilder: (PaneID) -> EmptyContent
    var showSplitButtons: Bool = true
    var contentViewLifecycle: ContentViewLifecycle = .recreateOnSwitch

    func makeCoordinator() -> Coordinator {
        Coordinator(splitState: splitState)
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = splitState.orientation == .horizontal
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        // First child
        let firstHosting = makeHostingView(for: splitState.first)
        splitView.addArrangedSubview(firstHosting)

        // Second child
        let secondHosting = makeHostingView(for: splitState.second)
        splitView.addArrangedSubview(secondHosting)

        context.coordinator.splitView = splitView

        // Capture animation origin before it gets cleared
        let animationOrigin = splitState.animationOrigin

        // Determine which pane is new (will be hidden initially)
        let newPaneIndex = animationOrigin == .fromFirst ? 0 : 1

        if animationOrigin != nil {
            // Clear immediately so we don't re-animate on updates
            splitState.animationOrigin = nil

            // Hide the NEW pane immediately to prevent flash
            splitView.arrangedSubviews[newPaneIndex].isHidden = true

            // Track that we're animating (skip delegate position updates)
            context.coordinator.isAnimating = true
        }

        // Wait for view to be added to window
        DispatchQueue.main.async {
            let totalSize = splitState.orientation == .horizontal
                ? splitView.bounds.width
                : splitView.bounds.height

            guard totalSize > 0 else { return }

            if animationOrigin != nil {
                // Position at edge while new pane is hidden
                let startPosition: CGFloat = animationOrigin == .fromFirst ? 0 : totalSize
                splitView.setPosition(startPosition, ofDividerAt: 0)
                splitView.layoutSubtreeIfNeeded()

                let targetPosition = totalSize * 0.5
                splitState.dividerPosition = 0.5

                // Wait for layout
                DispatchQueue.main.async {
                    // Show the new pane and animate
                    splitView.arrangedSubviews[newPaneIndex].isHidden = false

                    SplitAnimator.shared.animate(
                        splitView: splitView,
                        from: startPosition,
                        to: targetPosition
                    ) {
                        context.coordinator.isAnimating = false
                    }
                }
            } else {
                // No animation - just set the position
                let position = totalSize * splitState.dividerPosition
                splitView.setPosition(position, ofDividerAt: 0)
            }
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update orientation if changed
        splitView.isVertical = splitState.orientation == .horizontal

        // Update children
        let subviews = splitView.arrangedSubviews
        if subviews.count >= 2 {
            updateHostingView(subviews[0], for: splitState.first)
            updateHostingView(subviews[1], for: splitState.second)
        }
    }

    // MARK: - Helpers

    private func makeHostingView(for node: SplitNode) -> NSView {
        let hostingController = NSHostingController(rootView: AnyView(makeView(for: node)))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController.view
    }

    private func updateHostingView(_ view: NSView, for node: SplitNode) {
        // Find the hosting controller's view and update it
        if let hostingView = view as? NSHostingView<AnyView> {
            hostingView.rootView = AnyView(makeView(for: node))
        }
    }

    @ViewBuilder
    private func makeView(for node: SplitNode) -> some View {
        switch node {
        case .pane(let paneState):
            PaneContainerView(
                pane: paneState,
                controller: controller,
                contentBuilder: contentBuilder,
                emptyPaneBuilder: emptyPaneBuilder,
                showSplitButtons: showSplitButtons,
                contentViewLifecycle: contentViewLifecycle
            )
        case .split(let nestedSplitState):
            SplitContainerView(
                splitState: nestedSplitState,
                controller: controller,
                contentBuilder: contentBuilder,
                emptyPaneBuilder: emptyPaneBuilder,
                showSplitButtons: showSplitButtons,
                contentViewLifecycle: contentViewLifecycle
            )
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSSplitViewDelegate {
        let splitState: SplitState
        weak var splitView: NSSplitView?
        var isAnimating = false

        init(splitState: SplitState) {
            self.splitState = splitState
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            // Skip position updates during animation
            guard !isAnimating else { return }
            guard let splitView = notification.object as? NSSplitView else { return }

            let totalSize = splitState.orientation == .horizontal
                ? splitView.bounds.width
                : splitView.bounds.height

            guard totalSize > 0 else { return }

            if let firstSubview = splitView.arrangedSubviews.first {
                let dividerPosition = splitState.orientation == .horizontal
                    ? firstSubview.frame.width
                    : firstSubview.frame.height

                Task { @MainActor in
                    self.splitState.dividerPosition = dividerPosition / totalSize
                }
            }
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Allow edge positions during animation
            guard !isAnimating else { return proposedMinimumPosition }
            return max(proposedMinimumPosition, TabBarMetrics.minimumPaneWidth)
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Allow edge positions during animation
            guard !isAnimating else { return proposedMaximumPosition }
            let totalSize = splitState.orientation == .horizontal
                ? splitView.bounds.width
                : splitView.bounds.height
            return min(proposedMaximumPosition, totalSize - TabBarMetrics.minimumPaneWidth)
        }
    }
}
