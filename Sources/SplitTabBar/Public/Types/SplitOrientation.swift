import Foundation

/// Orientation for splitting panes
public enum SplitOrientation: String, Codable, Sendable {
    /// Side-by-side split (left | right)
    case horizontal
    /// Stacked split (top / bottom)
    case vertical
}
