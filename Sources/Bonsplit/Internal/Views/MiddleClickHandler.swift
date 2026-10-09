import AppKit
import SwiftUI

extension View {
    /// Performs `action` when the view is clicked with the middle mouse button.
    /// Every other mouse event passes through to the view as usual.
    func onMiddleClick(perform action: @escaping () -> Void) -> some View {
        overlay(MiddleClickHandler(action: action))
    }
}

/// SwiftUI's tap gestures only respond to the primary button, so middle clicks are caught by
/// a transparent AppKit view that only takes part in hit-testing for middle-button events.
private struct MiddleClickHandler: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> MiddleClickView {
        MiddleClickView()
    }

    func updateNSView(_ nsView: MiddleClickView, context: Context) {
        nsView.action = action
    }
}

final class MiddleClickView: NSView {
    static let middleButton = 2

    var action: (() -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent,
              event.type == .otherMouseDown || event.type == .otherMouseUp,
              event.buttonNumber == Self.middleButton else {
            return nil
        }
        return super.hitTest(point)
    }

    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == Self.middleButton else {
            super.otherMouseDown(with: event)
            return
        }
    }

    /// Fires on release, and only if the pointer is still over the view (like a regular click).
    override func otherMouseUp(with event: NSEvent) {
        guard event.buttonNumber == Self.middleButton else {
            super.otherMouseUp(with: event)
            return
        }
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            action?()
        }
    }
}
