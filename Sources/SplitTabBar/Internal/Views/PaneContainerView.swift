import SwiftUI
import UniformTypeIdentifiers

/// Drop zone positions for creating splits
enum DropZone: Equatable {
    case center
    case left
    case right
    case top
    case bottom

    var orientation: SplitOrientation? {
        switch self {
        case .left, .right: return .horizontal
        case .top, .bottom: return .vertical
        case .center: return nil
        }
    }

    var insertsFirst: Bool {
        switch self {
        case .left, .top: return true
        default: return false
        }
    }
}

/// Container for a single pane with its tab bar and content area
struct PaneContainerView<Content: View, EmptyContent: View>: View {
    @Bindable var pane: PaneState
    let controller: SplitViewController
    let contentBuilder: (TabItem, PaneID) -> Content
    let emptyPaneBuilder: (PaneID) -> EmptyContent
    var showSplitButtons: Bool = true
    var contentViewLifecycle: ContentViewLifecycle = .recreateOnSwitch

    @State private var activeDropZone: DropZone?

    private var isFocused: Bool {
        controller.focusedPaneId == pane.id
    }

    /// Whether this pane should show full saturation (focused, drag source, or drop target)
    private var shouldShowFullSaturation: Bool {
        isFocused ||
        controller.dragSourcePaneId == pane.id ||
        activeDropZone != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            TabBarView(
                pane: pane,
                controller: controller,
                isFocused: isFocused,
                showSplitButtons: showSplitButtons
            )

            // Content area with drop zones
            contentAreaWithDropZones
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .saturation(shouldShowFullSaturation ? 1.0 : 0)
    }

    // MARK: - Content Area with Drop Zones

    @ViewBuilder
    private var contentAreaWithDropZones: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Main content
                contentArea

                // Drop zones layer (above content, receives drops and taps)
                dropZonesLayer(size: size)

                // Visual placeholder (non-interactive)
                dropPlaceholder(for: activeDropZone, in: size)
                    .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
        }
        .clipped()
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if pane.tabs.isEmpty {
            emptyPaneView
        } else {
            switch contentViewLifecycle {
            case .recreateOnSwitch:
                // Original behavior: only render selected tab
                if let selectedTab = pane.selectedTab {
                    contentBuilder(selectedTab, pane.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

            case .keepAllAlive:
                // macOS-like behavior: keep all tab views in hierarchy
                ZStack {
                    ForEach(pane.tabs) { tab in
                        contentBuilder(tab, pane.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(tab.id == pane.selectedTabId ? 1 : 0)
                            .allowsHitTesting(tab.id == pane.selectedTabId)
                    }
                }
            }
        }
    }

    // MARK: - Drop Zones Layer

    @ViewBuilder
    private func dropZonesLayer(size: CGSize) -> some View {
        // Single unified drop zone that determines zone based on position
        Color.clear
            .onTapGesture {
                controller.focusPane(pane.id)
            }
            .onDrop(of: [.text], delegate: UnifiedPaneDropDelegate(
                size: size,
                pane: pane,
                controller: controller,
                activeDropZone: $activeDropZone
            ))
    }

    // MARK: - Drop Placeholder

    @ViewBuilder
    private func dropPlaceholder(for zone: DropZone?, in size: CGSize) -> some View {
        let placeholderColor = Color.accentColor.opacity(0.25)
        let borderColor = Color.accentColor
        let padding: CGFloat = 4

        // Calculate frame based on zone
        let frame: CGRect = {
            switch zone {
            case .center, .none:
                return CGRect(x: padding, y: padding, width: size.width - padding * 2, height: size.height - padding * 2)
            case .left:
                return CGRect(x: padding, y: padding, width: size.width / 2 - padding, height: size.height - padding * 2)
            case .right:
                return CGRect(x: size.width / 2, y: padding, width: size.width / 2 - padding, height: size.height - padding * 2)
            case .top:
                return CGRect(x: padding, y: padding, width: size.width - padding * 2, height: size.height / 2 - padding)
            case .bottom:
                return CGRect(x: padding, y: size.height / 2, width: size.width - padding * 2, height: size.height / 2 - padding)
            }
        }()

        RoundedRectangle(cornerRadius: 8)
            .fill(placeholderColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2)
            )
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .opacity(zone != nil ? 1 : 0)
            .animation(.spring(duration: 0.25, bounce: 0.15), value: zone)
    }

    // MARK: - Empty Pane View

    @ViewBuilder
    private var emptyPaneView: some View {
        emptyPaneBuilder(pane.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Unified Pane Drop Delegate

struct UnifiedPaneDropDelegate: DropDelegate {
    let size: CGSize
    let pane: PaneState
    let controller: SplitViewController
    @Binding var activeDropZone: DropZone?

    // Calculate zone based on position within the view
    private func zoneForLocation(_ location: CGPoint) -> DropZone {
        let edgeRatio: CGFloat = 0.25
        let horizontalEdge = max(80, size.width * edgeRatio)
        let verticalEdge = max(80, size.height * edgeRatio)

        // Check edges first (left/right take priority at corners)
        if location.x < horizontalEdge {
            return .left
        } else if location.x > size.width - horizontalEdge {
            return .right
        } else if location.y < verticalEdge {
            return .top
        } else if location.y > size.height - verticalEdge {
            return .bottom
        } else {
            return .center
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        let zone = zoneForLocation(info.location)

        guard let provider = info.itemProviders(for: [.text]).first else {
            activeDropZone = nil
            // Clear drag state
            controller.draggingTab = nil
            controller.dragSourcePaneId = nil
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                activeDropZone = nil
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

                // Find source pane
                guard let sourcePaneId = controller.rootNode.allPaneIds.first(where: { $0.id == transfer.sourcePaneId }) else {
                    return
                }

                if zone == .center {
                    // Drop in center - move tab to this pane
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        controller.moveTab(transfer.tab, from: sourcePaneId, to: pane.id, atIndex: nil)
                    }
                } else if let orientation = zone.orientation {
                    // Drop on edge - create a split (120fps animation handled by SplitAnimator)
                    // Remove tab from source first
                    if let sourcePane = controller.rootNode.findPane(sourcePaneId) {
                        sourcePane.removeTab(transfer.tab.id)

                        // Close empty source pane if not the only one
                        if sourcePane.tabs.isEmpty && controller.rootNode.allPaneIds.count > 1 {
                            controller.closePane(sourcePaneId)
                        }
                    }

                    // Create the split
                    controller.splitPaneWithTab(
                        pane.id,
                        orientation: orientation,
                        tab: transfer.tab,
                        insertFirst: zone.insertsFirst
                    )
                }
            }
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        activeDropZone = zoneForLocation(info.location)
    }

    func dropExited(info: DropInfo) {
        activeDropZone = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        activeDropZone = zoneForLocation(info.location)
        return DropProposal(operation: .move)
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
