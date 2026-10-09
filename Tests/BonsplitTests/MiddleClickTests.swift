import AppKit
import SwiftUI
import XCTest
@testable import Bonsplit

/// Clicks go through the application's event queue so that `NSApp.currentEvent` is set during
/// hit-testing, like it is for real input.
@MainActor
final class MiddleClickTests: XCTestCase {
    private static let left = 0, right = 1, middle = 2, back = 3

    private var window: NSWindow!
    private var middleClicks = 0
    private var taps = 0

    override func setUp() async throws {
        _ = NSApplication.shared
        middleClicks = 0
        taps = 0
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        // Windows that aren't on screen don't receive mouse events.
        window.alphaValue = 0
        show(
            Color.white
                .frame(width: 100, height: 50)
                .contentShape(Rectangle())
                .onTapGesture { [unowned self] in taps += 1 }
                .onMiddleClick { [unowned self] in middleClicks += 1 }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        )
        window.orderFrontRegardless()
    }

    override func tearDown() async throws {
        window.close()
        window = nil
    }

    func testMiddleClickPerformsAction() {
        click(.otherMouseDown, .otherMouseUp, button: Self.middle, at: NSPoint(x: 50, y: 25))
        XCTAssertEqual(middleClicks, 1)
        XCTAssertEqual(taps, 0)
    }

    func testMiddleClickOutsideViewIsIgnored() {
        click(.otherMouseDown, .otherMouseUp, button: Self.middle, at: NSPoint(x: 150, y: 75))
        XCTAssertEqual(middleClicks, 0)
    }

    func testMiddleClickReleasedOutsideViewIsIgnored() {
        send(.otherMouseDown, button: Self.middle, at: NSPoint(x: 50, y: 25))
        send(.otherMouseUp, button: Self.middle, at: NSPoint(x: 150, y: 75))
        XCTAssertEqual(middleClicks, 0)
    }

    func testOtherButtonsAreIgnored() {
        click(.otherMouseDown, .otherMouseUp, button: Self.back, at: NSPoint(x: 50, y: 25))
        XCTAssertEqual(middleClicks, 0)
    }

    func testLeftClickReachesTheView() {
        click(.leftMouseDown, .leftMouseUp, button: Self.left, at: NSPoint(x: 50, y: 25))
        XCTAssertEqual(taps, 1)
        XCTAssertEqual(middleClicks, 0)
    }

    func testOnlyMiddleButtonEventsHitTheHandler() {
        let point = NSPoint(x: 50, y: 25)
        XCTAssertTrue(hitView(.otherMouseDown, button: Self.middle, at: point) is MiddleClickView)
        XCTAssertFalse(hitView(.leftMouseDown, button: Self.left, at: point) is MiddleClickView)
        XCTAssertFalse(hitView(.rightMouseDown, button: Self.right, at: point) is MiddleClickView)
        XCTAssertFalse(hitView(.otherMouseDown, button: Self.back, at: point) is MiddleClickView)
    }

    func testMiddleClickClosesTab() throws {
        let controller = BonsplitController()
        let pane = try XCTUnwrap(controller.focusedPaneId)
        // Next to the initial "Welcome" tab.
        controller.createTab(title: "Second", icon: nil)
        show(BonsplitView(controller: controller) { _, _ in Color.clear })
        let tabs = controller.tabs(inPane: pane)
        XCTAssertEqual(tabs.count, 2)

        // Over the first tab's title, in the tab bar at the top of the window.
        click(.otherMouseDown, .otherMouseUp, button: Self.middle, at: NSPoint(x: 40, y: 300 - 16))

        XCTAssertEqual(controller.tabs(inPane: pane).map(\.id), [tabs[1].id])
    }

    // MARK: - Helpers

    private func show(_ view: some View) {
        window.contentView = NSHostingView(rootView: view.frame(width: 400, height: 300))
        window.contentView?.layoutSubtreeIfNeeded()
    }

    private func click(_ down: NSEvent.EventType, _ up: NSEvent.EventType, button: Int, at point: NSPoint) {
        send(down, button: button, at: point)
        send(up, button: button, at: point)
    }

    private func send(_ type: NSEvent.EventType, button: Int, at point: NSPoint) {
        window.sendEvent(dequeue(type, button: button, at: point))
    }

    /// The view the window would deliver the event to.
    private func hitView(_ type: NSEvent.EventType, button: Int, at point: NSPoint) -> NSView? {
        _ = dequeue(type, button: button, at: point)
        return window.contentView?.hitTest(point)
    }

    /// Posts a mouse event at `point` (window coordinates) and takes it back off the queue,
    /// which makes it `NSApp.currentEvent`.
    private func dequeue(_ type: NSEvent.EventType, button: Int, at point: NSPoint) -> NSEvent {
        let event = NSEvent.mouseEvent(
            with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        )!.cgEvent!
        // `mouseEvent(with:...)` can't set the button number.
        event.setIntegerValueField(.mouseEventButtonNumber, value: Int64(button))
        NSApp.postEvent(NSEvent(cgEvent: event)!, atStart: true)
        let dequeued = NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true)!
        XCTAssertEqual(dequeued.buttonNumber, button)
        XCTAssertIdentical(NSApp.currentEvent, dequeued)
        return dequeued
    }
}
