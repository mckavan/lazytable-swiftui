//
//  ResolvedLayout.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import SwiftUI

/// The integral ranges of columns and rows currently intersecting the viewport.
struct VisibleBounds: Equatable {
    var columns: Range<Int>
    var rows: Range<Int>

    static let empty = VisibleBounds(columns: 0..<0, rows: 0..<0)
}

/// A single registered cell with its absolute position in content coordinates.
struct ResolvedCell: Identifiable {
    let id: AnyHashable
    let rect: CGRect
    let lockedHorizontally: Bool
    let lockedVertically: Bool
    let isFooter: Bool
    let zIndex: Double
    let content: () -> AnyView
}

/// Geometry of the whole table, resolved once from dimensions, pin configuration and
/// the registered item intervals. Mirrors the Kotlin `LazyTablePxDimensions` +
/// `LazyTablePositionProvider` pair.
final class ResolvedLayout {
    /// Prefix sums of column widths; `columnEdges[c]` is the x where column `c` starts.
    /// Contains `columnCount + 1` entries.
    let columnEdges: [CGFloat]

    /// Prefix sums of row heights; `rowEdges[r]` is the y where row `r` starts.
    let rowEdges: [CGFloat]

    let totalSize: CGSize
    let pinConfiguration: LazyTablePinConfiguration

    /// Cells not pinned on any axis.
    let unpinnedCells: [ResolvedCell]

    /// Cells pinned horizontally, vertically or both (including the footer).
    let pinnedCells: [ResolvedCell]

    var columnCount: Int { columnEdges.count - 1 }
    var rowCount: Int { rowEdges.count - 1 }

    init(
        intervals: [LazyTableItemInterval],
        dimensions: LazyTableDimensions,
        pinConfiguration: LazyTablePinConfiguration
    ) {
        self.pinConfiguration = pinConfiguration

        // Evaluate layout info once per item; the table size is derived from the
        // furthest occupied cell (the same contract as the Kotlin library, where
        // dimensions must cover all registered items).
        var items: [(item: LazyTableItem, interval: LazyTableItemInterval, index: Int)] = []
        var columnCount = 0
        var rowCount = 0
        for interval in intervals {
            for index in 0..<interval.count {
                let item = interval.layoutInfo(index)
                columnCount = max(columnCount, item.column + item.columnsCount)
                rowCount = max(rowCount, item.row + item.rowsCount)
                items.append((item, interval, index))
            }
        }

        let columnWidths: [CGFloat]
        let rowHeights: [CGFloat]
        switch dimensions {
        case let .exact(columnsSize, rowsSize):
            precondition(
                columnsSize.count >= columnCount,
                "LazyTableDimensions.exact must specify at least \(columnCount) column sizes"
            )
            precondition(
                rowsSize.count >= rowCount,
                "LazyTableDimensions.exact must specify at least \(rowCount) row sizes"
            )
            columnWidths = Array(columnsSize.prefix(columnCount))
            rowHeights = Array(rowsSize.prefix(rowCount))
        case let .dynamic(columnSize, rowSize):
            columnWidths = (0..<columnCount).map(columnSize)
            rowHeights = (0..<rowCount).map(rowSize)
        }

        var columnEdges: [CGFloat] = [0]
        columnEdges.reserveCapacity(columnCount + 1)
        for width in columnWidths {
            columnEdges.append(columnEdges[columnEdges.count - 1] + width)
        }
        var rowEdges: [CGFloat] = [0]
        rowEdges.reserveCapacity(rowCount + 1)
        for height in rowHeights {
            rowEdges.append(rowEdges[rowEdges.count - 1] + height)
        }
        self.columnEdges = columnEdges
        self.rowEdges = rowEdges
        self.totalSize = CGSize(
            width: columnEdges[columnCount],
            height: rowEdges[rowCount]
        )

        var unpinned: [ResolvedCell] = []
        var pinned: [ResolvedCell] = []
        for (item, interval, index) in items {
            let rect = CGRect(
                x: columnEdges[item.column],
                y: rowEdges[item.row],
                width: columnEdges[item.column + item.columnsCount] - columnEdges[item.column],
                height: rowEdges[item.row + item.rowsCount] - rowEdges[item.row]
            )
            let isFooter = pinConfiguration.footer && item.row == rowCount - 1
            let lockedHorizontally = item.column < pinConfiguration.columns(item.row)
            let lockedVertically = isFooter || item.row < pinConfiguration.rows(item.column)
            let zIndex: Double = if lockedHorizontally && lockedVertically {
                3
            } else if lockedVertically {
                2
            } else if lockedHorizontally {
                1
            } else {
                0
            }
            let cell = ResolvedCell(
                id: interval.key?(index) ?? AnyHashable(item),
                rect: rect,
                lockedHorizontally: lockedHorizontally,
                lockedVertically: lockedVertically,
                isFooter: isFooter,
                zIndex: zIndex,
                content: { [content = interval.content] in content(index) }
            )
            if lockedHorizontally || lockedVertically {
                pinned.append(cell)
            } else {
                unpinned.append(cell)
            }
        }
        self.unpinnedCells = unpinned
        self.pinnedCells = pinned
    }

    // MARK: - Visibility

    /// The integral column/row ranges intersecting `rect`.
    func visibleIndexBounds(for rect: CGRect) -> VisibleBounds {
        VisibleBounds(
            columns: indexRange(edges: columnEdges, from: rect.minX, to: rect.maxX),
            rows: indexRange(edges: rowEdges, from: rect.minY, to: rect.maxY)
        )
    }

    /// The content rect covered by `bounds`, snapped to cell edges. Superset of the
    /// viewport rect the bounds were computed from, so rect-intersection against it
    /// never misses a visible cell.
    func rect(for bounds: VisibleBounds) -> CGRect {
        guard !bounds.columns.isEmpty, !bounds.rows.isEmpty else { return .zero }
        let minX = columnEdges[bounds.columns.lowerBound]
        let maxX = columnEdges[bounds.columns.upperBound]
        let minY = rowEdges[bounds.rows.lowerBound]
        let maxY = rowEdges[bounds.rows.upperBound]
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Unpinned cells intersecting `rect`.
    ///
    /// Linear scan over cell metadata; cheap structs only, views are not created here.
    func visibleUnpinnedCells(in rect: CGRect) -> [ResolvedCell] {
        unpinnedCells.filter { $0.rect.intersects(rect) }
    }

    /// Pinned cells visible for `rect`. A cell locked on one axis only needs to
    /// overlap the visible range on its free axis; cells locked on both axes (and the
    /// footer corner) are always visible.
    func visiblePinnedCells(in rect: CGRect) -> [ResolvedCell] {
        pinnedCells.filter { cell in
            let overlapsX = cell.rect.maxX > rect.minX && cell.rect.minX < rect.maxX
            let overlapsY = cell.rect.maxY > rect.minY && cell.rect.minY < rect.maxY
            if cell.lockedHorizontally && cell.lockedVertically {
                return true
            } else if cell.lockedHorizontally {
                return overlapsY
            } else {
                return overlapsX
            }
        }
    }

    // MARK: - Programmatic scrolling

    /// The content offset that places the given cell at `alignment` inside the
    /// non-pinned area of the viewport. Mirrors `LazyTablePositionProvider.getCellOffset`.
    func scrollTarget(
        column: Int,
        row: Int,
        columnsCount: Int = 1,
        rowsCount: Int = 1,
        alignment: UnitPoint,
        viewport: CGSize
    ) -> CGPoint {
        let column = min(max(column, 0), columnCount - 1)
        let row = min(max(row, 0), rowCount - 1)
        let cellX = columnEdges[column]
        let cellY = rowEdges[row]
        let cellWidth = columnEdges[min(column + columnsCount, columnCount)] - cellX
        let cellHeight = rowEdges[min(row + rowsCount, rowCount)] - cellY

        let pinnedWidth = columnEdges[min(pinConfiguration.columns(row), columnCount)]
        let pinnedHeight = rowEdges[min(pinConfiguration.rows(column), rowCount)]

        let availableWidth = viewport.width - pinnedWidth
        let availableHeight = viewport.height - pinnedHeight

        var target = CGPoint(
            x: cellX - pinnedWidth - (availableWidth - cellWidth) * alignment.x,
            y: cellY - pinnedHeight - (availableHeight - cellHeight) * alignment.y
        )
        target.x = min(max(target.x, 0), max(0, totalSize.width - viewport.width))
        target.y = min(max(target.y, 0), max(0, totalSize.height - viewport.height))
        return target
    }

    // MARK: - Helpers

    /// Indices `i` where the span `edges[i]..<edges[i + 1]` overlaps `from..<to`.
    private func indexRange(edges: [CGFloat], from: CGFloat, to: CGFloat) -> Range<Int> {
        let count = edges.count - 1
        guard count > 0, to > edges[0], from < edges[count] else { return 0..<0 }
        // First index whose end edge is beyond `from`.
        let lower = firstIndex(of: edges, where: { $0 > from }, in: 1...count) - 1
        // First index whose start edge is at or beyond `to`.
        let upper = firstIndex(of: edges, where: { $0 >= to }, in: 0...count)
        return lower..<max(min(upper, count), lower)
    }

    /// Binary search: the first index in `range` satisfying `predicate`, assuming the
    /// predicate is monotonic over the sorted `edges`. Returns `range.upperBound` if
    /// no index satisfies it.
    private func firstIndex(
        of edges: [CGFloat],
        where predicate: (CGFloat) -> Bool,
        in range: ClosedRange<Int>
    ) -> Int {
        var low = range.lowerBound
        var high = range.upperBound
        while low < high {
            let mid = (low + high) / 2
            if predicate(edges[mid]) {
                high = mid
            } else {
                low = mid + 1
            }
        }
        return low
    }
}
