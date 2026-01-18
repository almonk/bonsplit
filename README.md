# Bonsplit

A native macOS tab bar library with split pane support for SwiftUI applications.

## Features

- Native macOS look and feel using system colors
- Drag-and-drop tab reordering within and between panes
- Horizontal and vertical split panes with smooth 120fps animations
- Configurable appearance and behavior
- Delegate callbacks for all tab and pane events
- Keyboard navigation between panes
- Optional macOS-like tab state preservation (scroll position, focus, @State)

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/almonk/bonsplit.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

## Quick Start

```swift
import SwiftUI
import Bonsplit

struct ContentView: View {
    @State private var controller = BonsplitController()
    @State private var documents: [TabID: Document] = [:]

    var body: some View {
        BonsplitView(controller: controller) { tab in
            // Content for each tab
            if let document = documents[tab.id] {
                DocumentEditor(document: document)
            }
        } emptyPane: { paneId in
            // Custom view for empty panes (optional)
            VStack {
                Text("No Open Files")
                Button("New File") {
                    createDocument(inPane: paneId)
                }
            }
        }
        .onAppear {
            // Create initial tab
            if let tabId = controller.createTab(title: "Untitled", icon: "doc.text") {
                documents[tabId] = Document()
            }
        }
    }
}
```

**Note:** Splits create empty panes by default, giving you full control. Use the `didSplitPane` delegate method to auto-create tabs if desired.

## API Reference

### BonsplitController

The main controller for managing tabs and panes.

#### Tab Operations

```swift
// Create a new tab
let tabId = controller.createTab(
    title: "Document.swift",
    icon: "swift",           // SF Symbol name (optional)
    isDirty: false,          // Show dirty indicator (optional)
    inPane: paneId           // Target pane (optional, defaults to focused)
)

// Update tab properties
controller.updateTab(tabId, title: "NewName.swift")
controller.updateTab(tabId, isDirty: true)
controller.updateTab(tabId, icon: "doc.text")

// Close a tab
controller.closeTab(tabId)

// Select a tab
controller.selectTab(tabId)

// Navigate tabs
controller.selectPreviousTab()
controller.selectNextTab()
```

#### Split Operations

```swift
// Split the focused pane (creates empty pane)
let newPaneId = controller.splitPane(orientation: .horizontal)  // Side-by-side
let newPaneId = controller.splitPane(orientation: .vertical)    // Stacked

// Split a specific pane
controller.splitPane(paneId, orientation: .horizontal)

// Split with a tab already in the new pane
controller.splitPane(orientation: .horizontal, withTab: Tab(title: "New", icon: "doc"))

// Close a pane
controller.closePane(paneId)
```

**Note:** By default, `splitPane()` creates an empty pane. You have full control over when and how to add tabs. Use the `didSplitPane` delegate callback to create a tab in the new pane if you want automatic tab creation.

#### Focus Management

```swift
// Get focused pane
let focusedPane = controller.focusedPaneId

// Focus a specific pane
controller.focusPane(paneId)

// Navigate between panes
controller.navigateFocus(direction: .left)
controller.navigateFocus(direction: .right)
controller.navigateFocus(direction: .up)
controller.navigateFocus(direction: .down)
```

#### Query Methods

```swift
// Get all tabs
let allTabs = controller.allTabIds

// Get all panes
let allPanes = controller.allPaneIds

// Get tab info
if let tab = controller.tab(tabId) {
    print(tab.title, tab.icon, tab.isDirty)
}

// Get tabs in a pane
let paneTabs = controller.tabs(inPane: paneId)

// Get selected tab in a pane
let selected = controller.selectedTab(inPane: paneId)
```

### Tab

Read-only snapshot of tab metadata.

```swift
public struct Tab {
    public let id: TabID
    public let title: String
    public let icon: String?
    public let isDirty: Bool
}
```

### BonsplitDelegate

Implement this protocol to receive callbacks about tab bar events.

```swift
class MyDelegate: BonsplitDelegate {
    // Veto tab creation
    func splitTabBar(_ controller: BonsplitController,
                     shouldCreateTab tab: Tab,
                     inPane pane: PaneID) -> Bool {
        return true  // Return false to prevent
    }

    // Veto tab close (e.g., prompt to save)
    func splitTabBar(_ controller: BonsplitController,
                     shouldCloseTab tab: Tab,
                     inPane pane: PaneID) -> Bool {
        if tab.isDirty {
            return showSaveConfirmation()
        }
        return true
    }

    // React to tab selection
    func splitTabBar(_ controller: BonsplitController,
                     didSelectTab tab: Tab,
                     inPane pane: PaneID) {
        updateWindowTitle(tab.title)
    }

    // React to splits - new panes are empty by default
    func splitTabBar(_ controller: BonsplitController,
                     didSplitPane originalPane: PaneID,
                     newPane: PaneID,
                     orientation: SplitOrientation) {
        // Option 1: Auto-create a tab
        controller.createTab(title: "Untitled", icon: "doc.text", inPane: newPane)

        // Option 2: Leave empty - the emptyPane view will be shown
    }
}
```

All delegate methods have default implementations and are optional.

#### Available Delegate Methods

| Method | Description |
|--------|-------------|
| `shouldCreateTab` | Called before creating a tab. Return `false` to prevent. |
| `didCreateTab` | Called after a tab is created. |
| `shouldCloseTab` | Called before closing a tab. Return `false` to prevent. |
| `didCloseTab` | Called after a tab is closed. |
| `didSelectTab` | Called when a tab is selected. |
| `didMoveTab` | Called when a tab is moved between panes. |
| `shouldSplitPane` | Called before creating a split. Return `false` to prevent. |
| `didSplitPane` | Called after a split is created. Use this to create a tab in the new empty pane. |
| `shouldClosePane` | Called before closing a pane. Return `false` to prevent. |
| `didClosePane` | Called after a pane is closed. |
| `didFocusPane` | Called when focus changes to a different pane. |

### BonsplitConfiguration

Configure behavior and appearance.

```swift
let config = BonsplitConfiguration(
    allowSplits: true,           // Enable split buttons and drag-to-split
    allowCloseTabs: true,        // Show close buttons on tabs
    allowCloseLastPane: false,   // Prevent closing the last pane
    allowTabReordering: true,    // Enable drag-to-reorder
    allowCrossPaneTabMove: true, // Enable moving tabs between panes
    autoCloseEmptyPanes: true,   // Close panes when last tab is closed
    contentViewLifecycle: .recreateOnSwitch,  // How tab views are managed
    appearance: .default
)

let controller = BonsplitController(configuration: config)
```

#### Content View Lifecycle

Controls how tab content views are managed when switching between tabs:

```swift
// Memory efficient (default) - only selected tab is rendered
// Loses scroll position, @State, focus when switching tabs
contentViewLifecycle: .recreateOnSwitch

// macOS-like behavior - all tab views stay in memory
// Preserves scroll position, @State, focus, text selection, etc.
contentViewLifecycle: .keepAllAlive
```

| Mode | Memory | State Preservation | Use Case |
|------|--------|-------------------|----------|
| `.recreateOnSwitch` | Low | None | Simple content, external state management |
| `.keepAllAlive` | Higher | Full | Complex views, scroll positions, form inputs |

#### Appearance Configuration

```swift
let appearance = BonsplitConfiguration.Appearance(
    tabBarHeight: 33,
    tabMinWidth: 140,
    tabMaxWidth: 220,
    tabSpacing: 0,
    minimumPaneWidth: 100,
    minimumPaneHeight: 100,
    showSplitButtons: true,
    animationDuration: 0.15,
    enableAnimations: true
)

let config = BonsplitConfiguration(appearance: appearance)
```

#### Configuration Presets

```swift
// Default configuration
BonsplitConfiguration.default

// Single pane mode (no splits)
BonsplitConfiguration.singlePane

// Read-only mode (no modifications)
BonsplitConfiguration.readOnly
```

## Examples

### Preserving Tab State

Use `.keepAllAlive` to preserve scroll position, focus, and `@State` when switching tabs:

```swift
struct EditorApp: View {
    @State private var controller: BonsplitController

    init() {
        let config = BonsplitConfiguration(
            contentViewLifecycle: .keepAllAlive  // Preserve state across tab switches
        )
        _controller = State(initialValue: BonsplitController(configuration: config))
    }

    var body: some View {
        BonsplitView(controller: controller) { tab, paneId in
            ScrollView {
                // Scroll position is preserved when switching tabs!
                LongDocumentView(tabId: tab.id)
            }
        }
    }
}
```

With `.keepAllAlive`:
- Scroll positions are preserved
- Text selections remain intact
- `@State` variables keep their values
- Focus stays where you left it
- Form inputs don't reset

### Document Editor

```swift
struct DocumentEditorApp: View {
    @State private var controller = BonsplitController()
    @State private var documents: [TabID: Document] = [:]
    @StateObject private var delegate = DocumentDelegate()

    var body: some View {
        BonsplitView(controller: controller) { tab in
            if let doc = documents[tab.id] {
                TextEditor(text: Binding(
                    get: { doc.content },
                    set: { newValue in
                        doc.content = newValue
                        controller.updateTab(tab.id, isDirty: true)
                    }
                ))
            }
        }
        .onAppear {
            controller.delegate = delegate
            delegate.documents = $documents
            delegate.controller = controller
            newDocument()
        }
        .toolbar {
            Button("New") { newDocument() }
            Button("Save") { saveCurrentDocument() }
        }
    }

    func newDocument() {
        let doc = Document()
        if let tabId = controller.createTab(title: doc.name, icon: "doc.text") {
            documents[tabId] = doc
        }
    }
}

class DocumentDelegate: ObservableObject, BonsplitDelegate {
    var documents: Binding<[TabID: Document]>?
    weak var controller: BonsplitController?

    func splitTabBar(_ controller: BonsplitController,
                     shouldCloseTab tab: Tab,
                     inPane pane: PaneID) -> Bool {
        guard tab.isDirty else { return true }

        let alert = NSAlert()
        alert.messageText = "Save \(tab.title)?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            // Save then close
            return true
        case .alertSecondButtonReturn:
            // Close without saving
            return true
        default:
            // Cancel
            return false
        }
    }

    func splitTabBar(_ controller: BonsplitController,
                     didCloseTab tabId: TabID,
                     fromPane pane: PaneID) {
        documents?.wrappedValue.removeValue(forKey: tabId)
    }
}
```

### Menu Commands

```swift
struct AppCommands: Commands {
    @FocusedObject var controller: BonsplitController?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab") {
                controller?.createTab(title: "Untitled", icon: "doc.text")
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Tab") {
                if let pane = controller?.focusedPaneId,
                   let tab = controller?.selectedTab(inPane: pane) {
                    controller?.closeTab(tab.id)
                }
            }
            .keyboardShortcut("w", modifiers: .command)
        }

        CommandMenu("View") {
            Button("Split Right") {
                controller?.splitPane(orientation: .horizontal)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Split Down") {
                controller?.splitPane(orientation: .vertical)
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
        }
    }
}
```

### Custom Empty Pane View

Customize what users see when a pane has no tabs:

```swift
struct MyApp: View {
    @State private var controller = BonsplitController()

    var body: some View {
        BonsplitView(controller: controller) { tab in
            TabContentView(tab: tab)
        } emptyPane: { paneId in
            // Fully customizable empty state
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)

                Text("No Open Files")
                    .font(.title2)

                HStack {
                    Button("New File") {
                        controller.createTab(title: "Untitled", icon: "doc", inPane: paneId)
                    }
                    .buttonStyle(.borderedProminent)

                    if controller.allPaneIds.count > 1 {
                        Button("Close Pane") {
                            controller.closePane(paneId)
                        }
                    }
                }
            }
        }
    }
}
```

If you don't provide an `emptyPane` builder, a default minimal view is shown.

### Auto-Create Tabs on Split

Use the delegate to automatically create a tab when a pane is split:

```swift
class MyDelegate: BonsplitDelegate {
    func splitTabBar(_ controller: BonsplitController,
                     didSplitPane originalPane: PaneID,
                     newPane: PaneID,
                     orientation: SplitOrientation) {
        // Automatically create a tab in the new pane
        controller.createTab(title: "Untitled", icon: "doc.text", inPane: newPane)
    }
}
```

### Custom Tab Content

```swift
enum TabContent {
    case editor(Document)
    case preview(URL)
    case settings
}

struct MyApp: View {
    @State private var controller = BonsplitController()
    @State private var content: [TabID: TabContent] = [:]

    var body: some View {
        BonsplitView(controller: controller) { tab in
            switch content[tab.id] {
            case .editor(let doc):
                DocumentEditor(document: doc)
            case .preview(let url):
                WebView(url: url)
            case .settings:
                SettingsView()
            case .none:
                EmptyView()
            }
        }
    }

    func openDocument(_ doc: Document) {
        if let tabId = controller.createTab(title: doc.name, icon: "doc.text") {
            content[tabId] = .editor(doc)
        }
    }

    func openPreview(_ url: URL) {
        if let tabId = controller.createTab(title: "Preview", icon: "globe") {
            content[tabId] = .preview(url)
        }
    }
}
```

## License

MIT License
