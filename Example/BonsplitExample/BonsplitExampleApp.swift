import SwiftUI
import Bonsplit

@main
struct BonsplitExampleApp: App {
    @StateObject private var debugState = DebugState()

    var body: some Scene {
        WindowGroup {
            ContentView(debugState: debugState)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands()
            DebugCommands()
        }

        Window("Geometry Debug", id: "debug") {
            DebugWindowView(debugState: debugState)
        }
        .defaultSize(width: 400, height: 600)
    }
}

struct DebugCommands: Commands {
    @Environment(\.openWindow) var openWindow

    var body: some Commands {
        CommandMenu("Debug") {
            Button("Show Geometry Debug") {
                openWindow(id: "debug")
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
        }
    }
}

struct AppCommands: Commands {
    @FocusedObject var appState: AppState?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab") {
                appState?.newTab()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Tab") {
                appState?.closeCurrentTab()
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button("Show Previous Tab") {
                appState?.controller.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])

            Button("Show Next Tab") {
                appState?.controller.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
        }

        CommandMenu("Split") {
            Button("Split Right") {
                appState?.splitHorizontal()
            }
            .keyboardShortcut("\\", modifiers: .command)

            Button("Split Down") {
                appState?.splitVertical()
            }
            .keyboardShortcut("\\", modifiers: [.command, .shift])

            Divider()

            Button("Navigate Left") {
                appState?.controller.navigateFocus(direction: .left)
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .option])

            Button("Navigate Right") {
                appState?.controller.navigateFocus(direction: .right)
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .option])

            Button("Navigate Up") {
                appState?.controller.navigateFocus(direction: .up)
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .option])

            Button("Navigate Down") {
                appState?.controller.navigateFocus(direction: .down)
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .option])
        }
    }
}
