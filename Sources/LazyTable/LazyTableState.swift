//
//  LazyTableState.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import SwiftUI

/// Holds the scroll state of a ``LazyTable`` and provides programmatic scrolling.
///
/// Create one and pass it to ``LazyTable/init(state:pinConfiguration:dimensions:scrollDirection:content:)``
/// to observe the current offset or to scroll to a cell.
@MainActor
@Observable
public final class LazyTableState {
    /// The current scroll offset in content coordinates.
    public internal(set) var offset: CGPoint

    /// The size of the visible viewport.
    public internal(set) var viewportSize: CGSize = .zero

    /// The current horizontal translation.
    public var translateX: CGFloat { offset.x }

    /// The current vertical translation.
    public var translateY: CGFloat { offset.y }

    var scrollPosition = ScrollPosition()

    /// The column/row ranges currently intersecting the viewport (plus overscan).
    /// Only mutated when the integral ranges change, so views depending on it are not
    /// invalidated on every scrolled point.
    var visibleBounds: VisibleBounds = .empty

    @ObservationIgnored var layout: ResolvedLayout?
    @ObservationIgnored let initialOffset: CGPoint
    @ObservationIgnored var didApplyInitialOffset = false

    /// Extra margin around the viewport, in points, for which cells are kept alive to
    /// reduce churn while scrolling.
    @ObservationIgnored private let overscan: CGFloat = 48

    /// - Parameter initialOffset: The offset the table is initially scrolled to.
    public init(initialOffset: CGPoint = .zero) {
        self.initialOffset = initialOffset
        self.offset = initialOffset
    }

    // MARK: - Programmatic scrolling

    /// Instantly scrolls so that the given cell is placed at `alignment` inside the
    /// non-pinned area of the viewport.
    public func snapToCell(
        column: Int,
        row: Int,
        columnsCount: Int = 1,
        rowsCount: Int = 1,
        alignment: UnitPoint = .topLeading
    ) {
        guard let target = scrollTarget(column, row, columnsCount, rowsCount, alignment) else { return }
        scrollPosition.scrollTo(point: target)
    }

    /// Animates the scroll so that the given cell is placed at `alignment` inside the
    /// non-pinned area of the viewport.
    public func animateToCell(
        column: Int,
        row: Int,
        columnsCount: Int = 1,
        rowsCount: Int = 1,
        alignment: UnitPoint = .topLeading,
        animation: Animation = .default
    ) {
        guard let target = scrollTarget(column, row, columnsCount, rowsCount, alignment) else { return }
        withAnimation(animation) {
            scrollPosition.scrollTo(point: target)
        }
    }

    private func scrollTarget(
        _ column: Int,
        _ row: Int,
        _ columnsCount: Int,
        _ rowsCount: Int,
        _ alignment: UnitPoint
    ) -> CGPoint? {
        layout?.scrollTarget(
            column: column,
            row: row,
            columnsCount: columnsCount,
            rowsCount: rowsCount,
            alignment: alignment,
            viewport: viewportSize
        )
    }

    // MARK: - Internal updates

    func update(
        layout: ResolvedLayout,
        contentOffset: CGPoint,
        containerSize: CGSize,
        insets: EdgeInsets
    ) {
        self.layout = layout
        // The raw content offset rests at (-insets.leading, -insets.top); shift it so
        // `offset` is a translation that is zero at rest, like the Compose original.
        // `containerSize` already excludes the insets, so it is the usable viewport.
        let translation = CGPoint(
            x: contentOffset.x + insets.leading,
            y: contentOffset.y + insets.top
        )
        if offset != translation {
            offset = translation
        }
        if viewportSize != containerSize {
            viewportSize = containerSize
        }
        // Content under translucent bars is still visible, so cull against the full
        // scroll view bounds (raw offset + container plus insets), not just the
        // unobstructed viewport.
        let visibleRect = CGRect(
            x: contentOffset.x,
            y: contentOffset.y,
            width: containerSize.width + insets.leading + insets.trailing,
            height: containerSize.height + insets.top + insets.bottom
        ).insetBy(dx: -overscan, dy: -overscan)
        let bounds = layout.visibleIndexBounds(for: visibleRect)
        if bounds != visibleBounds {
            visibleBounds = bounds
        }
    }
}
