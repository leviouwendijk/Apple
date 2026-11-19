import Foundation

struct NumbersSnapshotTransport:
    Decodable
{
    let name: String
    let sheets: [Sheet]

    struct Sheet:
        Decodable
    {
        let index: Int
        let name: String
        let tables: [Table]
    }

    struct Table:
        Decodable
    {
        let index: Int
        let name: String

        let rowCount: Int
        let columnCount: Int

        let headerRowCount: Int
        let headerColumnCount: Int
        let footerRowCount: Int

        let rows: [Row]
    }

    struct Row:
        Decodable
    {
        let index: Int
        let cells: [Cell]
    }

    struct Cell:
        Decodable
    {
        let row: Int
        let column: Int
        let address: String

        let value: Value
        let format: String
        let formula: String?
        let formatted: String?
    }

    struct Value:
        Decodable
    {
        let kind: String

        let text: String?
        let number: String?
        let boolean: Bool?
        let date: String?
    }

    static func decode(
        _ data: Data
    ) throws -> NumbersSnapshot {
        let transport: Self

        do {
            transport =
                try JSONDecoder().decode(
                    Self.self,
                    from: data
                )
        } catch {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    String(
                        describing: error
                    )
                )
        }

        return try transport.snapshot()
    }

    func snapshot()
        throws -> NumbersSnapshot
    {
        NumbersSnapshot(
            name: name,
            sheets:
                try sheets.map {
                    try $0.snapshot()
                }
        )
    }
}

private extension NumbersSnapshotTransport.Sheet {
    func snapshot()
        throws -> NumbersSheetSnapshot
    {
        NumbersSheetSnapshot(
            index: index,
            name: name,
            tables:
                try tables.map {
                    try $0.snapshot()
                }
        )
    }
}

private extension NumbersSnapshotTransport.Table {
    func snapshot()
        throws -> NumbersTableSnapshot
    {
        NumbersTableSnapshot(
            index: index,
            name: name,
            rowCount: rowCount,
            columnCount: columnCount,
            headerRowCount: headerRowCount,
            headerColumnCount: headerColumnCount,
            footerRowCount: footerRowCount,
            rows:
                try rows.map {
                    try $0.snapshot()
                }
        )
    }
}

private extension NumbersSnapshotTransport.Row {
    func snapshot()
        throws -> NumbersRowSnapshot
    {
        NumbersRowSnapshot(
            index: index,
            cells:
                try cells.map {
                    try $0.snapshot()
                }
        )
    }
}

private extension NumbersSnapshotTransport.Cell {
    func snapshot()
        throws -> NumbersCellSnapshot
    {
        NumbersCellSnapshot(
            row: row,
            column: column,
            address: address,
            value:
                try value.snapshot(),
            format:
                NumbersCellFormat(
                    rawValue: format
                ),
            formula: formula,
            formatted: formatted
        )
    }
}

private extension NumbersSnapshotTransport.Value {
    func snapshot()
        throws -> NumbersCellValue
    {
        switch kind {
        case "empty":
            return .empty

        case "text":
            guard let text else {
                throw invalid(
                    "text value missing text payload"
                )
            }

            return .text(
                text
            )

        case "number":
            guard
                let number,
                let decimal = Decimal(
                    string: number,
                    locale:
                        Locale(
                            identifier:
                                "en_US_POSIX"
                        )
                )
            else {
                throw invalid(
                    "number value missing or invalid numeric payload"
                )
            }

            return .number(
                decimal
            )

        case "boolean":
            guard let boolean else {
                throw invalid(
                    "boolean value missing boolean payload"
                )
            }

            return .boolean(
                boolean
            )

        case "date":
            guard
                let date,
                let value = dateValue(
                    date
                )
            else {
                throw invalid(
                    "date value missing or invalid ISO-8601 payload"
                )
            }

            return .date(
                value
            )

        default:
            throw invalid(
                "unsupported primitive kind '\(kind)'"
            )
        }
    }

    func invalid(
        _ message: String
    ) -> AppleNumbersError {
        .invalidSnapshotTransport(
            message
        )
    }

    func dateValue(
        _ value: String
    ) -> Date? {
        let fractional =
            ISO8601DateFormatter()

        fractional.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]

        if let date =
            fractional.date(
                from: value
            )
        {
            return date
        }

        let regular =
            ISO8601DateFormatter()

        regular.formatOptions = [
            .withInternetDateTime,
        ]

        return regular.date(
            from: value
        )
    }
}
