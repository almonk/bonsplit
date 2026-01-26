import SwiftUI
import AppKit
import Bonsplit

struct DebugWindowView: View {
    @ObservedObject var debugState: DebugState

    var body: some View {
        VStack(spacing: 0) {
            // Split between geometry and logs
            VSplitView {
                // Pane Geometry Section
                if let snapshot = debugState.currentSnapshot {
                    GeometrySection(snapshot: snapshot, debugState: debugState)
                } else {
                    Text("No snapshot - waiting for layout")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Live Log Section
                LogSection(logs: debugState.logs, onClear: { debugState.logs.removeAll() })
            }
        }
        .frame(minWidth: 350, minHeight: 400)
        .modifier(UtilityWindowModifier())
    }
}

struct GeometrySection: View {
    let snapshot: LayoutSnapshot
    @ObservedObject var debugState: DebugState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Layout Snapshot").font(.subheadline)
                Text("Container: \(Int(snapshot.containerFrame.width)) x \(Int(snapshot.containerFrame.height)) at (\(Int(snapshot.containerFrame.x)), \(Int(snapshot.containerFrame.y)))")
                    .font(.caption2.monospaced())

                Divider()

                Text("Panes (\(snapshot.panes.count))").font(.caption)

                ForEach(snapshot.panes, id: \.paneId) { pane in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(String(pane.paneId.prefix(8)) + "...")
                                    .font(.caption2.monospaced())
                                if pane.paneId == snapshot.focusedPaneId {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }
                            }
                            Text("pos: (\(Int(pane.frame.x)), \(Int(pane.frame.y)))")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            Text("size: \(Int(pane.frame.width)) x \(Int(pane.frame.height))")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            Text("tabs: \(pane.tabIds.count)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Divider controls (if splits exist)
                if let tree = debugState.currentTree {
                    Divider()
                    Text("Splits").font(.caption)
                    SplitControlsView(node: tree, debugState: debugState)
                }
            }
            .padding(8)
        }
    }
}

struct SplitControlsView: View {
    let node: ExternalTreeNode
    @ObservedObject var debugState: DebugState

    var body: some View {
        switch node {
        case .pane:
            EmptyView()
        case .split(let split):
            VStack(alignment: .leading, spacing: 4) {
                DividerSlider(split: split, debugState: debugState)
                SplitControlsView(node: split.first, debugState: debugState)
                SplitControlsView(node: split.second, debugState: debugState)
            }
        }
    }
}

struct DividerSlider: View {
    let split: ExternalSplitNode
    @ObservedObject var debugState: DebugState
    @State private var position: Double

    init(split: ExternalSplitNode, debugState: DebugState) {
        self.split = split
        self.debugState = debugState
        self._position = State(initialValue: split.dividerPosition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(split.id.prefix(8))...")
                    .font(.caption2.monospaced())
                Text("(\(split.orientation))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f", position))
                    .font(.caption2.monospaced())
            }
            Slider(value: $position, in: 0.1...0.9)
                .onChange(of: position) { _, newValue in
                    if let id = UUID(uuidString: split.id) {
                        debugState.setDividerPosition(CGFloat(newValue), splitId: id)
                    }
                }
        }
        .padding(.vertical, 2)
        .onChange(of: split.dividerPosition) { _, newValue in
            position = newValue
        }
    }
}

struct LogSection: View {
    let logs: [String]
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Event Log").font(.subheadline)
                Spacer()
                Button("Clear") { onClear() }
                    .buttonStyle(.plain)
                    .font(.caption)
            }
            .padding(8)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: logs.count) { _, _ in
                    if let last = logs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct UtilityWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.styleMask.insert(.utilityWindow)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    DebugWindowView(debugState: DebugState())
}
