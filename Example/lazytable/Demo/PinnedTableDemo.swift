//
//  PinnedTableDemo.swift
//  lazytable
//
//  Demo mirroring the LazyTable repo's "pinned columns and rows" example.
//

import SwiftUI
import LazyTable

struct PinnedTableDemo: View {
    private static let dataColumns = 15
    private static let dataRows = 50

    /// Header row + data rows + footer row.
    private static let columns = dataColumns + 1
    private static let rows = dataRows + 2

    @State private var tableState = LazyTableState()

    var body: some View {
        LazyTable(
            state: tableState,
            pinConfiguration: lazyTablePinConfiguration(columns: 1, rows: 1, footer: true),
            dimensions: lazyTableDimensions(
                columnSize: { $0 == 0 ? 140 : 90 },
                rowSize: { _ in 44 }
            )
        ) { scope in
            scope.items(
                count: Self.columns * Self.rows,
                layoutInfo: {
                    LazyTableItem(column: $0 % Self.columns, row: $0 / Self.columns)
                }
            ) { index in
                cell(column: index % Self.columns, row: index / Self.columns)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Pinned table")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Scroll to top leading") {
                        tableState.animateToCell(column: 0, row: 0)
                    }
                    Button("Scroll to random cell (centered)") {
                        tableState.animateToCell(
                            column: Int.random(in: 1..<Self.columns),
                            row: Int.random(in: 1...Self.dataRows),
                            alignment: .center
                        )
                    }
                } label: {
                    Image(systemName: "scope")
                }
            }
        }
    }

    @ViewBuilder
    private func cell(column: Int, row: Int) -> some View {
        let isHeader = row == 0
        let isFooter = row == Self.rows - 1
        let isNameColumn = column == 0

        let text: String = if isHeader {
            isNameColumn ? "Item" : "Stat \(column)"
        } else if isFooter {
            isNameColumn ? "Total" : "\((row + column) * column)"
        } else if isNameColumn {
            "Item #\(row)"
        } else {
            "\(row * column)"
        }

        let background: Color = if isHeader || isFooter {
            Color(.systemGray4)
        } else if isNameColumn {
            Color(.systemGray6)
        } else {
            Color(.systemBackground)
        }

        Text(text)
            .font(isHeader || isFooter || isNameColumn ? .subheadline.bold() : .subheadline)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background)
            .overlay {
                Rectangle()
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            }
    }
}

#Preview {
    NavigationStack {
        PinnedTableDemo()
    }
}
