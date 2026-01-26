import SwiftUI
import Bonsplit

/// Observable state for the geometry debug panel
@MainActor
class DebugState: ObservableObject {
    @Published var logs: [String] = []
    @Published var currentSnapshot: LayoutSnapshot?
    @Published var currentTree: ExternalTreeNode?

    weak var controller: BonsplitController?

    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
        // Keep last 100 logs
        if logs.count > 100 {
            logs.removeFirst(logs.count - 100)
        }
    }

    func refresh() {
        guard let controller else { return }
        currentSnapshot = controller.layoutSnapshot()
        currentTree = controller.treeSnapshot()
        log("Refreshed: \(currentSnapshot?.panes.count ?? 0) panes")
    }

    func setDividerPosition(_ position: CGFloat, splitId: UUID) {
        guard let controller else { return }
        controller.setDividerPosition(position, forSplit: splitId, fromExternal: true)
    }
}
