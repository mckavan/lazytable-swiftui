//
//  LazyTableDimensions.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import Foundation

/// Defines the sizes of the columns and the rows of a lazy table.
public enum LazyTableDimensions {
    /// Sizes are taken from predefined lists. Each list must contain at least as many
    /// entries as the table has columns / rows.
    case exact(columnsSize: [CGFloat], rowsSize: [CGFloat])

    /// Sizes are calculated per index.
    case dynamic(columnSize: (Int) -> CGFloat, rowSize: (Int) -> CGFloat)
}

/// Creates dimensions where all columns share the same width and all rows share the same height.
public func lazyTableDimensions(
    columnSize: CGFloat = LazyTableDefaults.columnWidth,
    rowSize: CGFloat = LazyTableDefaults.rowHeight
) -> LazyTableDimensions {
    .dynamic(columnSize: { _ in columnSize }, rowSize: { _ in rowSize })
}

/// Creates dimensions from explicit lists of column widths and row heights.
public func lazyTableDimensions(
    columnsSize: [CGFloat],
    rowsSize: [CGFloat]
) -> LazyTableDimensions {
    .exact(columnsSize: columnsSize, rowsSize: rowsSize)
}

/// Creates dimensions where sizes are calculated per column / row index.
public func lazyTableDimensions(
    columnSize: @escaping (Int) -> CGFloat,
    rowSize: @escaping (Int) -> CGFloat
) -> LazyTableDimensions {
    .dynamic(columnSize: columnSize, rowSize: rowSize)
}

/// Default values used by ``LazyTable``.
public enum LazyTableDefaults {
    /// The default width of a column.
    public static let columnWidth: CGFloat = 96

    /// The default height of a row.
    public static let rowHeight: CGFloat = 48

    /// The default dimensions.
    public static func dimensions() -> LazyTableDimensions {
        lazyTableDimensions()
    }

    /// The default pin configuration: nothing is pinned.
    public static func pinConfiguration() -> LazyTablePinConfiguration {
        LazyTablePinConfiguration()
    }
}
