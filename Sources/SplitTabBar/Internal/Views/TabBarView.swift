import SwiftUI
import UniformTypeIdentifiers

/// Tab bar view with scrollable tabs, drag/drop support, and split buttons
struct TabBarView: View {
    @Bindable var pane: PaneState
    let controller: SplitViewController
    let isFocused: Bool
    var showSplitButtons: Bool = true

    @State private var dropTargetIndex: Int?
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private var canScrollLeft: Bool {
        scrollOffset > 1
    }

    private var canScrollRight: Bool {
        contentWidth > containerWidth && scrollOffset < contentWidth - containerWidth - 1
    }

    var body: some View {
        HStack(spacing: 0) {
            // Scrollable tabs with fade overlays
            GeometryReader { containerGeo in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: TabBarMetrics.tabSpacing) {
                            ForEach(Array(pane.tabs.enumerated()), id: \.element.id) { index, tab in
                                tabItem(for: tab, at: index)
                                    .id(tab.id)
                            }

                            // Drop zone at end of tabs
                            dropZoneAtEnd
                        }
                        .padding(.horizontal, TabBarMetrics.barPadding)
                        .background(
                            GeometryReader { contentGeo in
                                Color.clear
                                    .onChange(of: contentGeo.frame(in: .named("tabScroll"))) { _, newFrame in
                                        scrollOffset = -newFrame.minX
                                        contentWidth = newFrame.width
                                    }
                                    .onAppear {
                                        let frame = contentGeo.frame(in: .named("tabScroll"))
                                        scrollOffset = -frame.minX
                                        contentWidth = frame.width
                                    }
                            }
                        )
                    }
                    .coordinateSpace(name: "tabScroll")
                    .onAppear {
                        containerWidth = containerGeo.size.width
                        if let tabId = pane.selectedTabId {
                            proxy.scrollTo(tabId, anchor: .center)
                        }
                    }
                    .onChange(of: containerGeo.size.width) { _, newWidth in
                        containerWidth = newWidth
                    }
                    .onChange(of: pane.selectedTabId) { _, newTabId in
                        if let tabId = newTabId {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(tabId, anchor: .center)
                            }
                        }
                    }
                }
                .frame(height: TabBarMetrics.barHeight)
                .overlay(fadeOverlays)
            }

            Spacer()

            // Split buttons
            if showSplitButtons {
                splitButtons
            }
        }
        .frame(height: TabBarMetrics.barHeight)
        .contentShape(Rectangle())
        .background(tabBarBackground)
    }

    // MARK: - Tab Item

    @ViewBuilder
    private func tabItem(for tab: TabItem, at index: Int) -> some View {
        TabItemView(
            tab: tab,
            isSelected: pane.selectedTabId == tab.id,
            onSelect: {
                withAnimation(.easeInOut(duration: TabBarMetrics.selectionDuration)) {
                    pane.selectTab(tab.id)
                    controller.focusPane(pane.id)
                }
            },
            onClose: {
                withAnimation(.easeInOut(duration: TabBarMetrics.closeDuration)) {
                    controller.closeTab(tab.id, inPane: pane.id)
                }
            }
        )
        .onDrag {
            createItemProvider(for: tab)
        } preview: {
            TabDragPreview(tab: tab)
        }
        .onDrop(of: [.text], delegate: TabDropDelegate(
            targetIndex: index,
            pane: pane,
            controller: controller,
            dropTargetIndex: $dropTargetIndex
        ))
        .overlay(alignment: .leading) {
            if dropTargetIndex == index {
                dropIndicator
            }
        }
    }

    // MARK: - Item Provider

    private func createItemProvider(for tab: TabItem) -> NSItemProvider {
        // Set drag source for visual feedback
        controller.draggingTab = tab
        controller.dragSourcePaneId = pane.id

        let transfer = TabTransferData(tab: tab, sourcePaneId: pane.id.id)
        if let data = try? JSONEncoder().encode(transfer),
           let string = String(data: data, encoding: .utf8) {
            return NSItemProvider(object: string as NSString)
        }
        return NSItemProvider()
    }

    // MARK: - Drop Zone at End

    @ViewBuilder
    private var dropZoneAtEnd: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 30, height: TabBarMetrics.tabHeight)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: TabDropDelegate(
                targetIndex: pane.tabs.count,
                pane: pane,
                controller: controller,
                dropTargetIndex: $dropTargetIndex
            ))
            .overlay(alignment: .leading) {
                if dropTargetIndex == pane.tabs.count {
                    dropIndicator
                }
            }
    }

    // MARK: - Drop Indicator

    @ViewBuilder
    private var dropIndicator: some View {
        Capsule()
            .fill(TabBarColors.dropIndicator)
            .frame(width: TabBarMetrics.dropIndicatorWidth, height: TabBarMetrics.dropIndicatorHeight)
            .offset(x: -1)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Split Buttons

    @ViewBuilder
    private var splitButtons: some View {
        HStack(spacing: 4) {
            Button {
                // 120fps animation handled by SplitAnimator
                controller.splitPane(pane.id, orientation: .horizontal)
            } label: {
                Image(systemName: "square.split.2x1")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Split Right")

            Button {
                // 120fps animation handled by SplitAnimator
                controller.splitPane(pane.id, orientation: .vertical)
            } label: {
                Image(systemName: "square.split.1x2")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Split Down")
        }
        .padding(.trailing, 8)
    }

    // MARK: - Fade Overlays

    @ViewBuilder
    private var fadeOverlays: some View {
        let fadeWidth: CGFloat = 24

        HStack(spacing: 0) {
            // Left fade
            LinearGradient(
                colors: [TabBarColors.barBackground, TabBarColors.barBackground.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeWidth)
            .opacity(canScrollLeft ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: canScrollLeft)
            .allowsHitTesting(false)

            Spacer()

            // Right fade
            LinearGradient(
                colors: [TabBarColors.barBackground.opacity(0), TabBarColors.barBackground],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeWidth)
            .opacity(canScrollRight ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: canScrollRight)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var tabBarBackground: some View {
        Rectangle()
            .fill(isFocused ? TabBarColors.barBackground : TabBarColors.barBackground.opacity(0.95))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(TabBarColors.separator)
                    .frame(height: 1)
            }
    }
}

// MARK: - Tab Drop Delegate

struct TabDropDelegate: DropDelegate {
    let targetIndex: Int
    let pane: PaneState
    let controller: SplitViewController
    @Binding var dropTargetIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        dropTargetIndex = nil

        guard let provider = info.itemProviders(for: [.text]).first else {
            // Clear drag state
            controller.draggingTab = nil
            controller.dragSourcePaneId = nil
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                // Clear drag state
                controller.draggingTab = nil
                controller.dragSourcePaneId = nil

                // Handle both Data and String representations
                let string: String?
                if let data = item as? Data {
                    string = String(data: data, encoding: .utf8)
                } else if let nsString = item as? NSString {
                    string = nsString as String
                } else if let str = item as? String {
                    string = str
                } else {
                    string = nil
                }

                guard let string, let transfer = decodeTransfer(from: string) else {
                    return
                }

                // Same pane - reorder
                if transfer.sourcePaneId == pane.id.id {
                    guard let sourceIndex = pane.tabs.firstIndex(where: { $0.id == transfer.tab.id }) else {
                        return
                    }
                    withAnimation(.spring(duration: TabBarMetrics.reorderDuration, bounce: TabBarMetrics.reorderBounce)) {
                        pane.moveTab(from: sourceIndex, to: targetIndex)
                    }
                } else {
                    // Different pane - transfer
                    guard let sourcePaneId = controller.rootNode.allPaneIds.first(where: { $0.id == transfer.sourcePaneId }) else {
                        return
                    }
                    withAnimation(.spring(duration: TabBarMetrics.reorderDuration, bounce: TabBarMetrics.reorderBounce)) {
                        controller.moveTab(transfer.tab, from: sourcePaneId, to: pane.id, atIndex: targetIndex)
                    }
                }
            }
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        dropTargetIndex = targetIndex
    }

    func dropExited(info: DropInfo) {
        if dropTargetIndex == targetIndex {
            dropTargetIndex = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }

    private func decodeTransfer(from string: String) -> TabTransferData? {
        guard let data = string.data(using: .utf8),
              let transfer = try? JSONDecoder().decode(TabTransferData.self, from: data) else {
            return nil
        }
        return transfer
    }
}
