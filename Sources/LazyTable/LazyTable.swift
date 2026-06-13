//
//  LazyTable.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import SwiftUI

/// A lazy layout that displays columns and rows of data on a two directional plane.
///
/// Only the cells intersecting the viewport are instantiated. Columns and rows can be
/// pinned via ``LazyTablePinConfiguration`` so they stay visible while scrolling, and
/// cell sizes are configured via ``LazyTableDimensions``.
///
/// ```swift
/// LazyTable(dimensions: lazyTableDimensions(columnSize: 48, rowSize: 32)) { scope in
///     scope.items(count: columns * rows, layoutInfo: {
///         LazyTableItem(column: $0 % columns, row: $0 / columns)
///     }) { index in
///         Text("#\(index)")
///     }
/// }
/// ```
@MainActor
public struct LazyTable: View {
    private let externalState: LazyTableState?
    private let scrollDirection: LazyTableScrollDirection
    private let layout: ResolvedLayout

    @State private var internalState = LazyTableState()

    /// - Parameters:
    ///   - state: The state to observe and control scrolling. A private instance is
    ///     used when not provided.
    ///   - pinConfiguration: Which columns / rows are pinned while scrolling.
    ///   - dimensions: The sizes of columns and rows.
    ///   - scrollDirection: Which scroll directions are allowed.
    ///   - content: Registers the table items on the given scope.
    public init(
        state: LazyTableState? = nil,
        pinConfiguration: LazyTablePinConfiguration = LazyTableDefaults.pinConfiguration(),
        dimensions: LazyTableDimensions = LazyTableDefaults.dimensions(),
        scrollDirection: LazyTableScrollDirection = .both,
        content: (LazyTableScope) -> Void
    ) {
        self.externalState = state
        self.scrollDirection = scrollDirection
        let scope = LazyTableScope()
        content(scope)
        self.layout = ResolvedLayout(
            intervals: scope.intervals,
            dimensions: dimensions,
            pinConfiguration: pinConfiguration
        )
    }

    private var state: LazyTableState { externalState ?? internalState }

    public var body: some View {
        ScrollView(scrollDirection.axes, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                UnpinnedCellsLayer(state: state, layout: layout)
                PinnedCellsLayer(state: state, layout: layout)
            }
            .frame(
                width: layout.totalSize.width,
                height: layout.totalSize.height,
                alignment: .topLeading
            )
        }
        .scrollPosition(Bindable(state).scrollPosition)
        .onScrollGeometryChange(for: ScrollSnapshot.self) { geometry in
            ScrollSnapshot(
                offset: geometry.contentOffset,
                container: geometry.containerSize,
                insets: geometry.contentInsets
            )
        } action: { _, snapshot in
            state.update(
                layout: layout,
                contentOffset: snapshot.offset,
                containerSize: snapshot.container,
                insets: snapshot.insets
            )
        }
        .onAppear {
            state.layout = layout
            if !state.didApplyInitialOffset {
                state.didApplyInitialOffset = true
                if state.initialOffset != .zero {
                    state.scrollPosition.scrollTo(point: state.initialOffset)
                }
            }
        }
        .clipped()
    }
}

private struct ScrollSnapshot: Equatable {
    var offset: CGPoint
    var container: CGSize
    var insets: EdgeInsets
}

/// Renders cells that scroll freely. Depends only on `state.visibleBounds`, which
/// changes when the visible cell ranges change — not on every scrolled point.
private struct UnpinnedCellsLayer: View {
    let state: LazyTableState
    let layout: ResolvedLayout

    var body: some View {
        let rect = layout.rect(for: state.visibleBounds)
        ForEach(layout.visibleUnpinnedCells(in: rect)) { cell in
            cell.content()
                .frame(width: cell.rect.width, height: cell.rect.height)
                .offset(x: cell.rect.minX, y: cell.rect.minY)
        }
    }
}

/// Renders pinned cells. Reads `state.offset` so it is re-evaluated on every scrolled
/// point to keep pinned cells locked to the viewport edges.
private struct PinnedCellsLayer: View {
    let state: LazyTableState
    let layout: ResolvedLayout

    var body: some View {
        let rect = layout.rect(for: state.visibleBounds)
        let viewport = state.viewportSize
        // Clamp so pinned cells travel with the content during overscroll bounce,
        // matching the native feel of pinned UITableView headers.
        let lockedOffset = CGPoint(
            x: min(max(state.offset.x, 0), max(0, layout.totalSize.width - viewport.width)),
            y: min(max(state.offset.y, 0), max(0, layout.totalSize.height - viewport.height))
        )
        ForEach(layout.visiblePinnedCells(in: rect)) { cell in
            let x = cell.lockedHorizontally ? lockedOffset.x + cell.rect.minX : cell.rect.minX
            let y = if cell.isFooter {
                lockedOffset.y + viewport.height - cell.rect.height
            } else if cell.lockedVertically {
                lockedOffset.y + cell.rect.minY
            } else {
                cell.rect.minY
            }
            cell.content()
                .frame(width: cell.rect.width, height: cell.rect.height)
                .offset(x: x, y: y)
                .zIndex(cell.zIndex)
        }
    }
}
