//
//  LazyTablePinConfiguration.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import Foundation

/// The configuration of pinned columns and rows.
///
/// Columns and rows are pinned from the beginning; they stay visible while the user
/// scrolls the table. The footer pins the last row to the bottom of the viewport.
public struct LazyTablePinConfiguration {
    /// The number of pinned columns for a given row.
    public let columns: (_ row: Int) -> Int

    /// The number of pinned rows for a given column.
    public let rows: (_ column: Int) -> Int

    /// Whether the last row should be pinned to the bottom as a footer.
    public let footer: Bool

    /// Creates a configuration with a fixed number of pinned columns and rows.
    public init(
        columns: Int = 0,
        rows: Int = 0,
        footer: Bool = false
    ) {
        self.init(columns: { _ in columns }, rows: { _ in rows }, footer: footer)
    }

    /// Creates a configuration where the number of pinned columns / rows can vary
    /// per row / column.
    public init(
        columns: @escaping (_ row: Int) -> Int,
        rows: @escaping (_ column: Int) -> Int,
        footer: Bool = false
    ) {
        self.columns = columns
        self.rows = rows
        self.footer = footer
    }
}

/// Creates a ``LazyTablePinConfiguration`` with a fixed number of pinned columns and rows.
public func lazyTablePinConfiguration(
    columns: Int = 0,
    rows: Int = 0,
    footer: Bool = false
) -> LazyTablePinConfiguration {
    LazyTablePinConfiguration(columns: columns, rows: rows, footer: footer)
}

/// Creates a ``LazyTablePinConfiguration`` where pinned counts vary per row / column.
public func lazyTablePinConfiguration(
    columns: @escaping (_ row: Int) -> Int,
    rows: @escaping (_ column: Int) -> Int,
    footer: Bool = false
) -> LazyTablePinConfiguration {
    LazyTablePinConfiguration(columns: columns, rows: rows, footer: footer)
}
