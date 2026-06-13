//
//  ResolvedLayoutTests.swift
//  LazyTableTests
//
//  Unit tests for the LazyTable geometry core.
//

import Testing
import SwiftUI
@testable import LazyTable

@MainActor
struct ResolvedLayoutTests {
    /// 4 columns × 3 rows grid with one cell per position.
    private func makeLayout(
        columns: Int = 4,
        rows: Int = 3,
        dimensions: LazyTableDimensions? = nil,
        pin: LazyTablePinConfiguration = LazyTablePinConfiguration()
    ) -> ResolvedLayout {
        let scope = LazyTableScope()
        scope.items(
            count: columns * rows,
            layoutInfo: { LazyTableItem(column: $0 % columns, row: $0 / columns) }
        ) { index in
            Text("#\(index)")
        }
        return ResolvedLayout(
            intervals: scope.intervals,
            dimensions: dimensions ?? lazyTableDimensions(columnSize: 100, rowSize: 50),
            pinConfiguration: pin
        )
    }

    @Test func prefixSumsAndTotalSize() {
        let layout = makeLayout(
            dimensions: lazyTableDimensions(columnsSize: [10, 20, 30, 40], rowsSize: [5, 15, 25])
        )
        #expect(layout.columnEdges == [0, 10, 30, 60, 100])
        #expect(layout.rowEdges == [0, 5, 20, 45])
        #expect(layout.totalSize == CGSize(width: 100, height: 45))
    }

    @Test func dynamicDimensionsResolvePerIndex() {
        let layout = makeLayout(
            dimensions: lazyTableDimensions(
                columnSize: { CGFloat(10 * ($0 + 1)) },
                rowSize: { _ in 50 }
            )
        )
        #expect(layout.columnEdges == [0, 10, 30, 60, 100])
        #expect(layout.totalSize.height == 150)
    }

    @Test func spannedItemSizeAndTableBounds() {
        let scope = LazyTableScope()
        scope.items(
            count: 1,
            layoutInfo: { _ in LazyTableItem(column: 1, row: 1, columnsCount: 2, rowsCount: 3) }
        ) { _ in Text("span") }
        let layout = ResolvedLayout(
            intervals: scope.intervals,
            dimensions: lazyTableDimensions(columnSize: 100, rowSize: 50),
            pinConfiguration: LazyTablePinConfiguration()
        )
        // The table extends to cover column 1 + 2 spans and row 1 + 3 spans.
        #expect(layout.columnCount == 3)
        #expect(layout.rowCount == 4)
        let cell = layout.unpinnedCells[0]
        #expect(cell.rect == CGRect(x: 100, y: 50, width: 200, height: 150))
    }

    @Test func visibleIndexBounds() {
        let layout = makeLayout(columns: 10, rows: 10)
        // Viewport fully inside the 1000×500 table.
        let bounds = layout.visibleIndexBounds(for: CGRect(x: 150, y: 60, width: 300, height: 100))
        #expect(bounds.columns == 1..<5) // columns covering x in [150, 450)
        #expect(bounds.rows == 1..<4)    // rows covering y in [60, 160)
    }

    @Test func visibleIndexBoundsClampsAtEdges() {
        let layout = makeLayout(columns: 4, rows: 3)
        // Overscrolled rect extending beyond the content on all sides.
        let bounds = layout.visibleIndexBounds(for: CGRect(x: -50, y: -50, width: 5000, height: 5000))
        #expect(bounds.columns == 0..<4)
        #expect(bounds.rows == 0..<3)

        let empty = layout.visibleIndexBounds(for: CGRect(x: 5000, y: 0, width: 100, height: 100))
        #expect(empty.columns.isEmpty)
    }

    @Test func cellsArePartitionedByPinning() {
        let layout = makeLayout(pin: lazyTablePinConfiguration(columns: 1, rows: 1, footer: true))
        // 4×3 grid: row 0 pinned (4 cells), column 0 adds rows 1-2 (2 cells),
        // footer row 2 adds columns 1-3 (3 cells).
        #expect(layout.pinnedCells.count == 4 + 2 + 3)
        #expect(layout.unpinnedCells.count == 12 - 9)

        let corner = layout.pinnedCells.first {
            $0.lockedHorizontally && $0.lockedVertically && !$0.isFooter
        }
        #expect(corner?.zIndex == 3)

        let footerCorner = layout.pinnedCells.first { $0.isFooter && $0.lockedHorizontally }
        #expect(footerCorner != nil)
        #expect(footerCorner?.zIndex == 3)
        #expect(footerCorner?.lockedVertically == true)

        let header = layout.pinnedCells.first { $0.lockedVertically && !$0.lockedHorizontally && !$0.isFooter }
        #expect(header?.zIndex == 2)

        let pinnedColumn = layout.pinnedCells.first { $0.lockedHorizontally && !$0.lockedVertically }
        #expect(pinnedColumn?.zIndex == 1)
    }

    @Test func visiblePinnedCellsFilterOnFreeAxisOnly() {
        let layout = makeLayout(columns: 10, rows: 10, pin: lazyTablePinConfiguration(columns: 1, rows: 1))
        // Viewport scrolled to the middle of the table.
        let rect = CGRect(x: 300, y: 150, width: 200, height: 100)
        let pinned = layout.visiblePinnedCells(in: rect)

        // Corner cell (0,0) always visible.
        #expect(pinned.contains { $0.lockedHorizontally && $0.lockedVertically })
        // Pinned column cells only for visible rows (y in [150, 250) → rows 3..<5).
        let columnCells = pinned.filter { $0.lockedHorizontally && !$0.lockedVertically }
        #expect(columnCells.count == 2)
        // Pinned row cells only for visible columns (x in [300, 500) → columns 3..<5).
        let rowCells = pinned.filter { $0.lockedVertically && !$0.lockedHorizontally }
        #expect(rowCells.count == 2)
    }

    @Test func scrollTargetAccountsForPinnedRegionAndClamps() {
        let layout = makeLayout(
            columns: 10,
            rows: 10,
            pin: lazyTablePinConfiguration(columns: 1, rows: 1)
        )
        let viewport = CGSize(width: 400, height: 300)

        // Top-leading: cell (3, 4) should land right after the pinned column/row.
        let target = layout.scrollTarget(column: 3, row: 4, alignment: .topLeading, viewport: viewport)
        #expect(target == CGPoint(x: 300 - 100, y: 200 - 50))

        // Clamped to zero for cells inside the pinned region.
        let origin = layout.scrollTarget(column: 0, row: 0, alignment: .topLeading, viewport: viewport)
        #expect(origin == .zero)

        // Clamped to the max offset for the last cell.
        let end = layout.scrollTarget(column: 9, row: 9, alignment: .topLeading, viewport: viewport)
        #expect(end == CGPoint(x: 1000 - 400, y: 500 - 300))
    }

    @Test func footerNaturalPositionIsLastRow() {
        let layout = makeLayout(pin: lazyTablePinConfiguration(footer: true))
        let footer = layout.pinnedCells.first { $0.isFooter }
        #expect(footer?.rect.minY == 100) // 3 rows × 50, footer is row 2.
        #expect(footer?.lockedVertically == true)
    }
}
