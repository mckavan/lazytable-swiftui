//
//  LazyTableScrollDirection.swift
//  LazyTable
//
//  SwiftUI port of https://github.com/oleksandrbalan/lazytable
//

import SwiftUI

/// Determines which directions are allowed to scroll.
public enum LazyTableScrollDirection: Sendable {
    /// Both horizontal and vertical scroll gestures are allowed.
    case both

    /// Only horizontal scroll gestures are allowed, useful for LazyRow-ish layouts.
    case horizontal

    /// Only vertical scroll gestures are allowed, useful for LazyColumn-ish layouts.
    case vertical

    var axes: Axis.Set {
        switch self {
        case .both: [.horizontal, .vertical]
        case .horizontal: .horizontal
        case .vertical: .vertical
        }
    }
}
