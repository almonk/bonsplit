import Foundation

/// Represents a tab's metadata (read-only snapshot for library consumers)
public struct Tab: Identifiable, Hashable, Sendable {
    public let id: TabID
    public let title: String
    public let icon: String?
    public let isDirty: Bool

    public init(id: TabID = TabID(), title: String, icon: String? = nil, isDirty: Bool = false) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isDirty = isDirty
    }

    internal init(from tabItem: TabItem) {
        self.id = TabID(id: tabItem.id)
        self.title = tabItem.title
        self.icon = tabItem.icon
        self.isDirty = tabItem.isDirty
    }
}
