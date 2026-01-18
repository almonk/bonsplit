import SwiftUI

/// Preview shown during tab drag operations
struct TabDragPreview: View {
    let tab: TabItem

    var body: some View {
        HStack(spacing: TabBarMetrics.contentSpacing) {
            if let iconName = tab.icon {
                Image(systemName: iconName)
                    .font(.system(size: TabBarMetrics.iconSize))
            }

            Text(tab.title)
                .font(.system(size: TabBarMetrics.titleFontSize))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: TabBarMetrics.tabCornerRadius, style: .continuous)
                .fill(TabBarColors.activeTabBackground)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
        .opacity(0.9)
    }
}
