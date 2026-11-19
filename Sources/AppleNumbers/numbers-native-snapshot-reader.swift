import Foundation

@_spi(Testing)
public extension NumbersPackageReader {
    static func nativeSnapshot(
        at documentURL: URL
    ) throws -> NumbersSnapshot {
        guard documentURL.isFileURL else {
            throw AppleNumbersError.invalidDocumentURL(
                documentURL.absoluteString
            )
        }

        guard FileManager.default.fileExists(
            atPath:
                documentURL.path
        ) else {
            throw AppleNumbersError.invalidDocumentURL(
                documentURL.path
            )
        }

        let graph =
            try nativeDocumentGraph(
                at:
                    documentURL
            )

        return try NumbersNativeSnapshotDecoder.decode(
            graph,
            documentURL:
                documentURL
        )
    }
}

private enum NumbersNativeSnapshotDecoder {
    static func decode(
        _ graph: NumbersNativeDocumentGraph,
        documentURL: URL
    ) throws -> NumbersSnapshot {
        let documentName =
            documentURL
                .lastPathComponent

        guard !documentName.isEmpty else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "native snapshot document name is empty"
                )
        }

        let sheets =
            try graph
                .sheets
                .enumerated()
                .map {
                    sheetOffset,
                    sheet in

                    NumbersSheetSnapshot(
                        index:
                            sheetOffset + 1,
                        name:
                            sheet.name,
                        tables:
                            try decodeTables(
                                sheet.tables
                            )
                    )
                }

        return NumbersSnapshot(
            name:
                documentName,
            sheets:
                sheets
        )
    }

    private static func decodeTables(
        _ tables: [NumbersNativeDocumentGraph.Table]
    ) throws -> [NumbersTableSnapshot] {
        try tables
            .enumerated()
            .map {
                tableOffset,
                table in

                NumbersTableSnapshot(
                    index:
                        tableOffset + 1,
                    name:
                        table.name,
                    rowCount:
                        table.rowCount,
                    columnCount:
                        table.columnCount,
                    headerRowCount:
                        table.headerRowCount,
                    headerColumnCount:
                        table.headerColumnCount,
                    footerRowCount:
                        table.footerRowCount,
                    rows:
                        try decodeRows(
                            table
                        )
                )
            }
    }

    private static func decodeRows(
        _ table: NumbersNativeDocumentGraph.Table
    ) throws -> [NumbersRowSnapshot] {
        guard
            table.rowCount >= 0,
            table.columnCount >= 0
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) has negative dimensions"
                )
        }

        var placedByGlobalRow:
            [Int: NumbersNativePlacedRow] = [:]

        for placedRow in table.placedRows {
            guard
                placedRow.globalRowIndex >= 0,
                placedRow.globalRowIndex
                    < table.rowCount
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) placed row \(placedRow.globalRowIndex) is outside row count \(table.rowCount)"
                    )
            }

            guard
                placedByGlobalRow.updateValue(
                    placedRow,
                    forKey:
                        placedRow.globalRowIndex
                )
                == nil
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) contains duplicate placed row \(placedRow.globalRowIndex)"
                    )
            }
        }

        return try (
            0..<table.rowCount
        )
        .map {
            zeroBasedRow in

            let records =
                placedByGlobalRow[
                    zeroBasedRow
                ]?
                .row
                .records
                ?? []

            let recordByColumn =
                try recordsByColumn(
                    records,
                    table:
                        table,
                    zeroBasedRow:
                        zeroBasedRow
                )

            let oneBasedRow =
                zeroBasedRow + 1

            let cells =
                try (
                    0..<table.columnCount
                )
                .map {
                    zeroBasedColumn in

                    let oneBasedColumn =
                        zeroBasedColumn + 1

                    return try decodeCell(
                        record:
                            recordByColumn[
                                zeroBasedColumn
                            ],
                        table:
                            table,
                        row:
                            oneBasedRow,
                        column:
                            oneBasedColumn
                    )
                }

            return NumbersRowSnapshot(
                index:
                    oneBasedRow,
                cells:
                    cells
            )
        }
    }

    private static func recordsByColumn(
        _ records:
            [NumbersNativeTableStorageProfile.CellRecord],
        table: NumbersNativeDocumentGraph.Table,
        zeroBasedRow: Int
    ) throws -> [
        Int:
            NumbersNativeTableStorageProfile.CellRecord
    ] {
        var result:
            [
                Int:
                    NumbersNativeTableStorageProfile.CellRecord
            ] = [:]

        for record in records {
            guard
                record.columnIndex >= 0,
                record.columnIndex
                    < table.columnCount
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) row \(zeroBasedRow) contains column \(record.columnIndex) outside column count \(table.columnCount)"
                    )
            }

            guard
                result.updateValue(
                    record,
                    forKey:
                        record.columnIndex
                )
                == nil
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) row \(zeroBasedRow) contains duplicate column \(record.columnIndex)"
                    )
            }
        }

        return result
    }

    private static func decodeCell(
        record:
            NumbersNativeTableStorageProfile.CellRecord?,
        table: NumbersNativeDocumentGraph.Table,
        row: Int,
        column: Int
    ) throws -> NumbersCellSnapshot {
        guard let record else {
            return NumbersCellSnapshot(
                row:
                    row,
                column:
                    column,
                address:
                    try a1Address(
                        row:
                            row,
                        column:
                            column
                    ),
                value:
                    .empty,
                format:
                    .automatic,
                formula:
                    nil,
                formatted:
                    nil
            )
        }

        let value =
            try primitiveValue(
                record,
                tableName:
                    table.name,
                row:
                    row,
                column:
                    column
            )

        let format =
            try snapshotPresentationFormat(
                record,
                table:
                    table
            )

        let formula =
            try formulaSource(
                key:
                    record.formulaKey,
                table:
                    table,
                row:
                    row,
                column:
                    column
            )

        let formatted =
            try NumbersNativeFormattedValueRenderer.render(
                value,
                record:
                    record,
                in:
                    table.modernDataLists
            )

        return NumbersCellSnapshot(
            row:
                row,
            column:
                column,
            address:
                try a1Address(
                    row:
                        row,
                    column:
                        column
                ),
            value:
                value,
            format:
                format,
            formula:
                formula,
            formatted:
                formatted
        )
    }

    private static func primitiveValue(
        _ record:
            NumbersNativeTableStorageProfile.CellRecord,
        tableName: String,
        row: Int,
        column: Int
    ) throws -> NumbersCellValue {
        if let value =
            record.primitiveValue
        {
            return value
        }

        if record.type == 0 {
            return .empty
        }

        throw NumbersObjectGraphError
            .invalidObjectGraph(
                "table \(tableName) R\(row)C\(column) BNC type \(record.type) has no characterized primitive value"
            )
    }

    private static func snapshotPresentationFormat(
        _ record:
            NumbersNativeTableStorageProfile.CellRecord,
        table: NumbersNativeDocumentGraph.Table
    ) throws -> NumbersCellFormat {
        let storedResultFormat =
            try NumbersNativeCellFormatResolver.resolve(
                record,
                in:
                    table.modernDataLists
            )

        guard record.formulaKey != nil else {
            return storedResultFormat
        }

        guard
            record.version == 5,
            record.type == 10,
            record.fieldMask == 0x0000_5201,
            record.suggestedFormatKind == 2,
            record.formatFamily == .currency,
            record.controlCellSpecKey == nil,
            record.unparsedTrailingByteCount == 0,
            storedResultFormat == .currency
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) formula cell has an uncharacterized presentation-format shape: type=\(record.type), mask=0x\(String(record.fieldMask, radix: 16)), suggested=\(record.suggestedFormatKind.map { String($0) } ?? "nil"), family=\(record.formatFamily?.rawValue ?? "nil"), control=\(record.controlCellSpecKey.map { String($0) } ?? "nil"), stored=\(storedResultFormat.rawValue)"
                )
        }

        return .automatic
    }

    private static func formulaSource(
        key: UInt32?,
        table: NumbersNativeDocumentGraph.Table,
        row: Int,
        column: Int
    ) throws -> String? {
        guard let key else {
            return nil
        }

        guard let formulaTable =
            table.formulas
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) R\(row)C\(column) references formula key \(key) without a formula table"
                )
        }

        let matches =
            formulaTable
                .formulas
                .filter {
                    $0.key == key
                }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) R\(row)C\(column) formula key \(key) resolved to \(matches.count) entries"
                )
        }

        return try matches[0].source(
            hostRow:
                row,
            hostColumn:
                column
        )
    }

    private static func a1Address(
        row: Int,
        column: Int
    ) throws -> String {
        guard
            row > 0,
            column > 0
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "native snapshot A1 address requires positive row and column"
                )
        }

        var remaining =
            column

        var scalars:
            [UnicodeScalar] = []

        while remaining > 0 {
            let zeroBased =
                remaining - 1

            let remainder =
                zeroBased % 26

            guard let scalar =
                UnicodeScalar(
                    65 + remainder
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "could not render native snapshot A1 column \(column)"
                    )
            }

            scalars.append(
                scalar
            )

            remaining =
                zeroBased / 26
        }

        return String(
            String.UnicodeScalarView(
                scalars.reversed()
            )
        )
        + String(
            row
        )
    }
}
