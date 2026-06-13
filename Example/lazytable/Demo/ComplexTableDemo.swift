//
//  ComplexTableDemo.swift
//  lazytable
//
//  A complex demo: two pinned columns (icon image + name), two pinned rows
//  (a spanning group banner + a header row), a pinned footer, image cells and
//  per-column widths.
//

import SwiftUI
import LazyTable

struct ComplexTableDemo: View {
    // MARK: - Table shape

    private static let dataColumns = 12
    private static let columns = dataColumns + 2   // 2 pinned: icon + name
    private static let dataRows = 40
    private static let rows = dataRows + 3         // banner + header + data + footer

    private static let bannerRow = 0
    private static let headerRow = 1
    private static let footerRow = rows - 1
    private static let firstDataRow = 2

    private static let columnTitles = [
        "Power", "Speed", "Range", "Crew", "Status", "Mission",
        "Fuel", "Mass", "Year", "Cost", "Rating", "Code",
    ]
    private static let columnWidths: [CGFloat] = [
        70, 70, 90, 60, 110, 150,
        70, 80, 70, 90, 110, 80,
    ]

    /// Column groups shown in the pinned banner row, as (title, start column, span).
    private static let bannerGroups: [(title: String, column: Int, span: Int)] = [
        ("Identity", 0, 2),
        ("Performance", 2, 4),
        ("Details", 6, 8),
    ]

    // MARK: - Data

    private struct Ship {
        let name: String
        let kind: String
        let symbol: String
        let color: Color
    }

    private static let ships: [Ship] = {
        let names = [
            "Aurora", "Borealis", "Cygnus", "Drake", "Eclipse", "Falcon",
            "Gemini", "Horizon", "Icarus", "Juno", "Kestrel", "Lyra",
            "Meridian", "Nautilus", "Orion", "Pulsar", "Quasar", "Raven",
            "Sirius", "Titan",
        ]
        let kinds = ["Freighter", "Scout", "Tanker", "Cruiser"]
        let symbols = [
            "airplane", "paperplane.fill", "bolt.fill", "flame.fill",
            "leaf.fill", "star.fill", "moon.fill", "sun.max.fill",
            "cloud.fill", "snowflake",
        ]
        let colors: [Color] = [.blue, .orange, .green, .purple, .red, .teal, .indigo, .pink]
        return (0..<dataRows).map { row in
            Ship(
                name: "\(names[row % names.count]) \(["I", "II", "III", "IV"][row / names.count % 4])",
                kind: kinds[row % kinds.count],
                symbol: symbols[row % symbols.count],
                color: colors[row % colors.count]
            )
        }
    }()

    private static func value(row: Int, column: Int) -> Int {
        ((row + 1) * (column + 3) * 37) % 950 + 50
    }

    private static let statuses: [(text: String, symbol: String, color: Color)] = [
        ("Active", "checkmark.circle.fill", .green),
        ("Docked", "pause.circle.fill", .blue),
        ("Repair", "wrench.and.screwdriver.fill", .orange),
        ("Transit", "arrow.right.circle.fill", .purple),
    ]

    // MARK: - View

    @State private var tableState = LazyTableState()

    var body: some View {
        LazyTable(
            state: tableState,
            pinConfiguration: lazyTablePinConfiguration(columns: 2, rows: 2, footer: true),
            dimensions: lazyTableDimensions(
                columnSize: { column in
                    switch column {
                    case 0: 64
                    case 1: 150
                    default: Self.columnWidths[column - 2]
                    }
                },
                rowSize: { row in
                    switch row {
                    case Self.bannerRow: 36
                    case Self.headerRow: 40
                    case Self.footerRow: 44
                    default: 56
                    }
                }
            )
        ) { scope in
            // Pinned banner row: three group titles spanning multiple columns.
            scope.items(
                Self.bannerGroups,
                layoutInfo: {
                    LazyTableItem(column: $0.column, row: Self.bannerRow, columnsCount: $0.span)
                },
                key: { AnyHashable("banner-\($0.column)") }
            ) { group in
                BannerCell(title: group.title)
            }

            // Pinned header row.
            scope.items(
                count: Self.columns,
                layoutInfo: { LazyTableItem(column: $0, row: Self.headerRow) }
            ) { column in
                HeaderCell(title: Self.headerTitle(column: column))
            }

            // Data cells, including the two pinned leading columns.
            scope.items(
                count: Self.columns * Self.dataRows,
                layoutInfo: {
                    LazyTableItem(
                        column: $0 % Self.columns,
                        row: $0 / Self.columns + Self.firstDataRow
                    )
                }
            ) { index in
                let column = index % Self.columns
                let dataRow = index / Self.columns
                DataCell(column: column, dataRow: dataRow, ship: Self.ships[dataRow])
            }

            // Pinned footer row.
            scope.items(
                count: Self.columns,
                layoutInfo: { LazyTableItem(column: $0, row: Self.footerRow) }
            ) { column in
                FooterCell(column: column)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Fleet overview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tableState.animateToCell(
                        column: Int.random(in: 2..<Self.columns),
                        row: Int.random(in: Self.firstDataRow...Self.dataRows),
                        alignment: .center
                    )
                } label: {
                    Image(systemName: "scope")
                }
            }
        }
    }

    private static func headerTitle(column: Int) -> String {
        switch column {
        case 0: ""
        case 1: "Vessel"
        default: columnTitles[column - 2]
        }
    }

    // MARK: - Cells

    private struct BannerCell: View {
        let title: String

        var body: some View {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.indigo.gradient)
                .overlay { CellBorder() }
        }
    }

    private struct HeaderCell: View {
        let title: String

        var body: some View {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray4))
                .overlay { CellBorder() }
        }
    }

    private struct FooterCell: View {
        let column: Int

        var body: some View {
            Text(text)
                .font(.subheadline.bold())
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray4))
                .overlay { CellBorder() }
        }

        private var text: String {
            switch column {
            case 0: return "Σ"
            case 1: return "\(ComplexTableDemo.dataRows) vessels"
            default:
                let total = (0..<ComplexTableDemo.dataRows)
                    .map { ComplexTableDemo.value(row: $0, column: column) }
                    .reduce(0, +)
                return "\(total)"
            }
        }
    }

    private struct DataCell: View {
        let column: Int
        let dataRow: Int
        let ship: Ship

        var body: some View {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(background)
                .overlay { CellBorder() }
        }

        @ViewBuilder
        private var content: some View {
            switch column {
            case 0:
                IconCell(ship: ship)
            case 1:
                NameCell(ship: ship)
            case 6: // Status
                StatusCell(dataRow: dataRow)
            case 12: // Rating
                RatingCell(dataRow: dataRow)
            default:
                Text(text)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }

        private var text: String {
            let value = ComplexTableDemo.value(row: dataRow, column: column)
            return switch column {
            case 4: "\(value) km"           // Range
            case 5: "\(value % 12 + 1)"     // Crew
            case 7: "Sector \(value % 24)"  // Mission
            case 8: "\(value % 90 + 10)%"   // Fuel
            case 9: "\(value) t"            // Mass
            case 10: "\(2390 + value % 60)" // Year
            case 11: "$\(value)K"           // Cost
            case 13: String(format: "VX-%03d", value) // Code
            default: "\(value)"
            }
        }

        private var background: Color {
            // Pinned cells overlay the scrolling content, so every cell background
            // must be fully opaque — a translucent fill lets cells bleed through.
            if column == 1 {
                Color(.systemGray6)
            } else if dataRow.isMultiple(of: 2) {
                Color(.systemBackground)
            } else {
                Color(white: 0.972)
            }
        }
    }

    private struct IconCell: View {
        let ship: Ship

        var body: some View {
            Image(systemName: ship.symbol)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(ship.color.gradient, in: .circle)
        }
    }

    private struct NameCell: View {
        let ship: Ship

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(ship.name)
                    .font(.subheadline.bold())
                Text(ship.kind)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
        }
    }

    private struct StatusCell: View {
        let dataRow: Int

        var body: some View {
            let status = ComplexTableDemo.statuses[dataRow % ComplexTableDemo.statuses.count]
            Label(status.text, systemImage: status.symbol)
                .font(.caption.bold())
                .foregroundStyle(status.color)
                .labelStyle(.titleAndIcon)
        }
    }

    private struct RatingCell: View {
        let dataRow: Int

        var body: some View {
            let stars = dataRow % 5 + 1
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    private struct CellBorder: View {
        var body: some View {
            Rectangle()
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        }
    }
}

#Preview {
    NavigationStack {
        ComplexTableDemo()
    }
}
