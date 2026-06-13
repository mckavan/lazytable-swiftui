# LazyTable for SwiftUI

A lazily-virtualized, two-directionally scrollable table for SwiftUI, with
pinned rows/columns, a pinned footer, multi-cell spans, per-column/row sizing,
and programmatic scrolling.

Only the cells intersecting the viewport are instantiated, so tables with
thousands of cells scroll smoothly. It's a SwiftUI port of the Kotlin/Compose
[lazytable](https://github.com/oleksandrbalan/lazytable) by Oleksandr Balan.

## Demos

| Pinned header, column & footer | Pinned groups, spans & image cells |
| :---: | :---: |
| <img width="300" height="652" alt="Pinned table demo" src="https://github.com/user-attachments/assets/477a9d45-9058-4120-9fac-a15f1a207d95" /> | <img width="300" height="652" alt="Complex table demo" src="https://github.com/user-attachments/assets/49fad5ff-00f0-48b0-aad9-02e052cafb81" /> |

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6 toolchain (Xcode 16+)

The library is built entirely on SwiftUI (`ScrollView` + `onScrollGeometryChange`
+ `ScrollPosition`) with no UIKit dependency, and compiles clean under the
Swift 6 language mode (full data-race safety).

## Installation

### Swift Package Manager

In Xcode: **File ▸ Add Package Dependencies…** and enter:

```
https://github.com/mckavan/lazytable-swiftui
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mckavan/lazytable-swiftui", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "LazyTable", package: "lazytable-swiftui"),
    ]),
]
```

Then `import LazyTable`.

## Quick start

```swift
import SwiftUI
import LazyTable

struct ContentView: View {
    let columns = 10
    let rows = 10

    var body: some View {
        LazyTable(dimensions: lazyTableDimensions(columnSize: 48, rowSize: 32)) { scope in
            scope.items(
                count: columns * rows,
                layoutInfo: { LazyTableItem(column: $0 % columns, row: $0 / columns) }
            ) { index in
                Text("#\(index)")
            }
        }
    }
}
```

## Pinned rows, columns and footer

Pin the first column and header row, and stick the last row to the bottom as a
footer:

```swift
LazyTable(
    pinConfiguration: lazyTablePinConfiguration(columns: 1, rows: 1, footer: true),
    dimensions: lazyTableDimensions(columnSize: 96, rowSize: 44)
) { scope in
    scope.items(count: count, layoutInfo: layout) { index in
        Cell(index)
    }
}
```

Pinned counts can also vary per row/column with the closure-based initializer:

```swift
lazyTablePinConfiguration(columns: { row in row == 0 ? 2 : 1 }, rows: { _ in 1 })
```

## Sizing

```swift
// Uniform
lazyTableDimensions(columnSize: 96, rowSize: 48)

// Per-index (e.g. a wide first column)
lazyTableDimensions(columnSize: { $0 == 0 ? 140 : 90 }, rowSize: { _ in 44 })

// Explicit lists
lazyTableDimensions(columnsSize: [140, 90, 90, 120], rowsSize: [36, 44, 44])
```

Cells can span multiple columns/rows:

```swift
LazyTableItem(column: 0, row: 0, columnsCount: 2, rowsCount: 1)
```

## Programmatic scrolling

Hold a `LazyTableState` to observe the offset and scroll to a cell:

```swift
@State private var tableState = LazyTableState()

LazyTable(state: tableState, /* … */) { scope in /* … */ }

// Later:
tableState.animateToCell(column: 5, row: 20, alignment: .center)
tableState.snapToCell(column: 0, row: 0)
```

`LazyTableState` also exposes the live `offset` / `translateX` / `translateY`.

## Scroll direction

Restrict scrolling to one axis with `scrollDirection: .horizontal` or
`.vertical` (default `.both`).

## Example app

The [`Example/`](Example/) directory contains a SwiftUI demo app with a pinned
header/column/footer table and a complex table (multiple pinned rows and
columns, image cells, varied column widths). Open `Example/lazytable.xcodeproj`
— it references this package as a local dependency.

## License

[MIT](LICENSE). Inspired by the Kotlin
[lazytable](https://github.com/oleksandrbalan/lazytable); see [NOTICE](NOTICE).
