import Foundation

/// Opaque identifier for panes
public struct PaneID: Hashable, Codable, Sendable {
    internal let id: UUID

    public init() {
        self.id = UUID()
    }

    internal init(id: UUID) {
        self.id = id
    }
}
