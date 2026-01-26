import SwiftUI
import Bonsplit

struct ContentView: View {
    @StateObject private var appState = AppState()
    @ObservedObject var debugState: DebugState

    var body: some View {
        BonsplitView(controller: appState.controller) { tab, paneId in
            TabContentView(tab: tab, paneId: paneId, appState: appState)
        } emptyPane: { paneId in
            EmptyPaneView(paneId: paneId, appState: appState)
        }
        .focusedSceneObject(appState)
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Create initial tab if none exist
            if appState.controller.allTabIds.isEmpty {
                appState.newTab()
            }
            // Wire up debug state
            appState.debugState = debugState
            debugState.controller = appState.controller
        }
    }
}

struct TabContentView: View {
    let tab: Bonsplit.Tab
    let paneId: PaneID
    @ObservedObject var appState: AppState
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Editor area
            if let content = appState.tabContents[tab.id] {
                TextEditor(text: Binding(
                    get: { content.text },
                    set: { newValue in
                        appState.tabContents[tab.id]?.text = newValue
                        appState.controller.updateTab(tab.id, isDirty: true)
                    }
                ))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .focused($isEditorFocused)
                .onChange(of: isEditorFocused) { _, focused in
                    if focused {
                        appState.controller.focusPane(paneId)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No content")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

/// Custom view for empty panes - developer can fully customize this
struct EmptyPaneView: View {
    let paneId: PaneID
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text("No Open Files")
                .font(.title2)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("New File") {
                    appState.newTab(inPane: paneId)
                }
                .buttonStyle(.borderedProminent)

                if appState.controller.allPaneIds.count > 1 {
                    Button("Close Pane") {
                        appState.closePane(paneId)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

#Preview {
    ContentView(debugState: DebugState())
}
