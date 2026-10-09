# Changelog

All notable changes to Bonsplit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Middle-clicking a tab closes it, like its close button

## [1.1.1] - 2025-01-29

### Fixed
- Fixed delegate notifications not being sent when closing tabs ([#2](https://github.com/almonk/bonsplit/issues/2))
  - Tabs now correctly communicate through `BonsplitController` for proper delegate callbacks

### Added
- New public method `closeTab(_ tabId: TabID, inPane paneId: PaneID) -> Bool` for efficient tab closing when pane is known

## [1.1.0] - 2025-01-26

### Added

#### Two-Way Synchronization API
- **Geometry Query**: Query pane layout with pixel coordinates for integration with external programs
  - `layoutSnapshot()` - Get flat list of pane geometries with pixel coordinates
  - `treeSnapshot()` - Get full tree structure for external consumption
  - `findSplit(_:)` - Check if a split exists by UUID

- **Programmatic Updates**: Control divider positions from external sources
  - `setDividerPosition(_:forSplit:fromExternal:)` - Set divider position with loop prevention
  - `setContainerFrame(_:)` - Update container frame when window moves/resizes

- **Geometry Notifications**: Receive callbacks when geometry changes
  - `didChangeGeometry` delegate callback - Notified when any pane geometry changes
  - `shouldNotifyDuringDrag` delegate callback - Opt-in to real-time notifications during divider drag

#### New Types
- `LayoutSnapshot` - Full tree snapshot with pixel coordinates and timestamp
- `PixelRect` - Pixel rectangle for external consumption (Codable, Sendable)
- `PaneGeometry` - Geometry for a single pane including frame and tab info
- `ExternalTreeNode` - Recursive tree representation (enum: pane or split)
- `ExternalPaneNode` - Pane node for external consumption
- `ExternalSplitNode` - Split node with orientation and divider position
- `ExternalTab` - Tab info for external consumption

#### Debug Tools
- Debug window in Example app for testing synchronization features

## [1.0.0] - Initial Release

### Added
- Tab bar with drag-and-drop reordering
- Horizontal and vertical split panes
- 120fps animations
- Configurable appearance and behavior
- Delegate callbacks for all tab and pane events
- Keyboard navigation between panes
- Content view lifecycle options (recreateOnSwitch, keepAllAlive)
- Configuration presets (default, singlePane, readOnly)
