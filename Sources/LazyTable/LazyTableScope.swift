//
//  LazyTableScope.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import SwiftUI

/// Receiver scope used by the ``LazyTable`` content closure to register items.
public final class LazyTableScope {
    var intervals: [LazyTableItemInterval] = []

    /// Adds `count` items to the table.
    ///
    /// - Parameters:
    ///   - count: The number of items.
    ///   - layoutInfo: Returns the position and span of the item at a given index.
    ///   - key: Optional stable identity for the item at a given index. Defaults to
    ///     the item's `(column, row)` position.
    ///   - content: Builds the cell view for a given index.
    public func items<Content: View>(
        count: Int,
        layoutInfo: @escaping (Int) -> LazyTableItem,
        key: ((Int) -> AnyHashable)? = nil,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        intervals.append(
            LazyTableItemInterval(
                count: count,
                layoutInfo: layoutInfo,
                key: key,
                content: { AnyView(content($0)) }
            )
        )
    }

    /// Adds all elements of `data` to the table.
    ///
    /// - Parameters:
    ///   - data: The items to display.
    ///   - layoutInfo: Returns the position and span of a given element.
    ///   - key: Optional stable identity for a given element. Defaults to the
    ///     element's `(column, row)` position.
    ///   - content: Builds the cell view for a given element.
    public func items<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        layoutInfo: @escaping (Data.Element) -> LazyTableItem,
        key: ((Data.Element) -> AnyHashable)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        let elements = Array(data)
        items(
            count: elements.count,
            layoutInfo: { layoutInfo(elements[$0]) },
            key: key.map { key in { key(elements[$0]) } },
            content: { content(elements[$0]) }
        )
    }
}

/// A registered run of items sharing the same layout and content builders.
struct LazyTableItemInterval {
    let count: Int
    let layoutInfo: (Int) -> LazyTableItem
    let key: ((Int) -> AnyHashable)?
    let content: (Int) -> AnyView
}
