import SwiftUI
import Bonsplit

/// Content associated with a tab
struct TabContent {
    var text: String
}

/// Application state managing tabs and their content
@MainActor
class AppState: ObservableObject {
    let controller: BonsplitController

    @Published var tabContents: [TabID: TabContent] = [:]

    /// Reference to debug state for geometry notifications
    weak var debugState: DebugState?

    private var tabCounter = 0

    init() {
        let config = BonsplitConfiguration(
            allowSplits: true,
            allowCloseTabs: true,
            allowCloseLastPane: false,
            // Use keepAllAlive to preserve scroll position, @State, and focus when switching tabs
            contentViewLifecycle: .keepAllAlive
        )
        self.controller = BonsplitController(configuration: config)
        self.controller.delegate = self
    }

    // MARK: - Tab Operations

    func newTab() {
        tabCounter += 1
        let title = "Untitled \(tabCounter)"

        if let tabId = controller.createTab(title: title, icon: "doc.text") {
            tabContents[tabId] = TabContent(text: sampleText(for: tabCounter))
            debugState?.refresh()
        }
    }

    func closeCurrentTab() {
        guard let paneId = controller.focusedPaneId,
              let tab = controller.selectedTab(inPane: paneId) else { return }
        _ = controller.closeTab(tab.id)
    }

    func splitHorizontal() {
        // Split creates empty pane - we create a tab via the delegate callback
        _ = controller.splitPane(orientation: .horizontal)
    }

    func splitVertical() {
        // Split creates empty pane - we create a tab via the delegate callback
        _ = controller.splitPane(orientation: .vertical)
    }

    /// Create a new tab in a specific pane (called from empty pane view or delegate)
    func newTab(inPane paneId: PaneID) {
        tabCounter += 1
        let title = "Untitled \(tabCounter)"

        if let tabId = controller.createTab(title: title, icon: "doc.text", inPane: paneId) {
            tabContents[tabId] = TabContent(text: sampleText(for: tabCounter))
            debugState?.refresh()
        }
    }

    /// Close a specific pane
    func closePane(_ paneId: PaneID) {
        _ = controller.closePane(paneId)
    }

    // MARK: - Sample Content

    private func sampleText(for index: Int) -> String {
        let samples = [
            "// Welcome to Bonsplit Example!\n\n// Try these actions:\n// - ⌘T to create a new tab\n// - ⌘W to close the current tab\n// - ⌘⇧D to split right\n// - ⌘⌥D to split down\n// - Drag tabs to reorder or move between panes\n// - ⌘⌥←→↑↓ to navigate between panes\n\nlet greeting = \"Hello, World!\"\nprint(greeting)",
            "import SwiftUI\n\nstruct MyView: View {\n    var body: some View {\n        Text(\"Hello from tab \\(index)\")\n            .font(.largeTitle)\n            .padding()\n    }\n}",
            "# Notes\n\nThis is a sample document.\n\n## Features\n\n- Drag and drop tabs\n- Split panes\n- Keyboard navigation\n\n## Tips\n\nTry dragging a tab to the edge of a pane to create a split!",
            "func fibonacci(_ n: Int) -> Int {\n    guard n > 1 else { return n }\n    return fibonacci(n - 1) + fibonacci(n - 2)\n}\n\nlet result = fibonacci(10)\nprint(\"Fibonacci(10) = \\(result)\")",
            "struct Document: Identifiable {\n    let id = UUID()\n    var title: String\n    var content: String\n    var isDirty: Bool = false\n}\n\nclass DocumentManager {\n    var documents: [Document] = []\n    \n    func save(_ document: Document) {\n        // Save implementation\n    }\n}"
        ]
        return samples[(index - 1) % samples.count]
    }
}

// MARK: - BonsplitDelegate

@MainActor
extension AppState: BonsplitDelegate {
    func splitTabBar(_ controller: BonsplitController,
                     shouldCloseTab tab: Bonsplit.Tab,
                     inPane pane: PaneID) -> Bool {
        // If tab is dirty, show confirmation
        if tab.isDirty {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to \"\(tab.title)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning

            switch alert.runModal() {
            case .alertFirstButtonReturn:
                // Save - in a real app, save the file here
                print("Saving \(tab.title)...")
                return true
            case .alertSecondButtonReturn:
                // Don't save - just close
                return true
            default:
                // Cancel
                return false
            }
        }
        return true
    }

    func splitTabBar(_ controller: BonsplitController,
                     didCloseTab tabId: TabID,
                     fromPane pane: PaneID) {
        // Clean up content when tab is closed
        tabContents.removeValue(forKey: tabId)
        debugState?.refresh()
    }

    func splitTabBar(_ controller: BonsplitController,
                     didSelectTab tab: Bonsplit.Tab,
                     inPane pane: PaneID) {
        // Update window title
        if let window = NSApp.keyWindow {
            window.title = tab.title
        }
    }

    func splitTabBar(_ controller: BonsplitController,
                     didSplitPane originalPane: PaneID,
                     newPane: PaneID,
                     orientation: SplitOrientation) {
        // Option 1: Auto-create a tab in the new pane
        newTab(inPane: newPane)

        // Option 2: Leave the pane empty and let user create content
        // (The emptyPane view will be shown - see ContentView)
    }

    func splitTabBar(_ controller: BonsplitController,
                     didChangeGeometry snapshot: LayoutSnapshot) {
        debugState?.log("Geometry changed: \(snapshot.panes.count) panes")
        debugState?.currentSnapshot = snapshot
        debugState?.currentTree = controller.treeSnapshot()
    }

    func splitTabBar(_ controller: BonsplitController,
                     shouldNotifyDuringDrag: Bool) -> Bool {
        // Enable real-time notifications during drag
        return true
    }
}
