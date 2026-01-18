import Foundation

/// Opaque identifier for tabs
public struct TabID: Hashable, Codable, Sendable {
    internal let id: UUID

    public init() {
        self.id = UUID()
    }

    internal init(id: UUID) {
        self.id = id
    }
}
