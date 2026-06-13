//
//  LazyTableItem.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import Foundation

/// The layout data for an item inside a lazy table.
public struct LazyTableItem: Hashable, Sendable {
    /// The index of the column.
    public let column: Int

    /// The index of the row.
    public let row: Int

    /// The count of columns occupied by the item.
    public let columnsCount: Int

    /// The count of rows occupied by the item.
    public let rowsCount: Int

    public init(
        column: Int,
        row: Int,
        columnsCount: Int = 1,
        rowsCount: Int = 1
    ) {
        self.column = column
        self.row = row
        self.columnsCount = columnsCount
        self.rowsCount = rowsCount
    }
}
