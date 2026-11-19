@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeSnapshotFlow: TestFlow {
        TestFlow(
            "numbers-native-snapshot",
            tags: [
                "numbers",
                "native",
                "snapshot",
                "integration",
            ]
        ) {
            Step(
                "Numbers workbook lowers to canonical snapshot and inferred schema"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix: "NativeFlow"
                    )

                defer {
                    try? FileManager.default
                        .removeItem(
                            at: directory
                        )
                }

                let documentURL =
                    directory
                        .appendingPathComponent(
                            "Native-Probe.numbers"
                        )

                try createNumbersFixture(
                    at: documentURL
                )

                let snapshot =
                    try AppleNumbers.snapshot(
                        at: documentURL
                    )

                let nativeStructure =
                    try NumbersPackageReader.structure(
                        at: documentURL
                    )

                let nativeStorage =
                    try NumbersPackageReader.storageProfile(
                        at: documentURL
                    )

                let nativeFormulas =
                    try NumbersPackageReader.formulaProfile(
                        at: documentURL
                    )

                let nativeFormats =
                    try NumbersPackageReader.formatProfile(
                        at: documentURL
                    )

                let nativeGraph =
                    try NumbersPackageReader.nativeDocumentGraph(
                        at: documentURL
                    )

                let nativeSnapshot =
                    try NumbersPackageReader.nativeSnapshot(
                        at: documentURL
                    )

                try Expect.equal(
                    nativeStructure.sheets.map(
                        \.name
                    ),
                    [
                        "Probe",
                    ],
                    "native-object-graph.sheet-order-and-names"
                )

                try Expect.equal(
                    nativeStructure
                        .sheets[0]
                        .tables
                        .map(
                            \.name
                        ),
                    [
                        "Clients",
                        "Invoices",
                    ],
                    "native-object-graph.table-order-and-names"
                )

                let directClients =
                    nativeStructure
                        .sheets[0]
                        .tables[0]

                let directInvoices =
                    nativeStructure
                        .sheets[0]
                        .tables[1]

                try Expect.equal(
                    directClients.rowCount,
                    4,
                    "native-object-graph.clients.row-count"
                )

                try Expect.equal(
                    directClients.columnCount,
                    5,
                    "native-object-graph.clients.column-count"
                )

                try Expect.equal(
                    directClients.headerRowCount,
                    1,
                    "native-object-graph.clients.header-row-count"
                )

                try Expect.equal(
                    directClients.headerColumnCount,
                    0,
                    "native-object-graph.clients.header-column-count"
                )

                try Expect.equal(
                    directClients.footerRowCount,
                    0,
                    "native-object-graph.clients.footer-row-count"
                )

                try Expect.equal(
                    directInvoices.rowCount,
                    5,
                    "native-object-graph.invoices.row-count"
                )

                try Expect.equal(
                    directInvoices.columnCount,
                    4,
                    "native-object-graph.invoices.column-count"
                )

                try Expect.equal(
                    directInvoices.headerRowCount,
                    1,
                    "native-object-graph.invoices.header-row-count"
                )

                try Expect.equal(
                    directInvoices.footerRowCount,
                    1,
                    "native-object-graph.invoices.footer-row-count"
                )

                print(
                    "SWIFT OBJECT GRAPH"
                )

                print(
                    "  sheets: "
                    + String(
                        nativeStructure
                            .sheets
                            .count
                    )
                )

                print(
                    "  ordered tables: "
                    + nativeStructure
                        .sheets[0]
                        .tables
                        .map(
                            \.name
                        )
                        .joined(
                            separator: ", "
                        )
                )

                try Expect.equal(
                    nativeGraph.sheets.map(
                        \.name
                    ),
                    [
                        "Probe",
                    ],
                    "native-consolidated.sheet-order"
                )

                try Expect.equal(
                    nativeGraph
                        .sheets[0]
                        .tables
                        .map(
                            \.name
                        ),
                    [
                        "Clients",
                        "Invoices",
                    ],
                    "native-consolidated.table-order"
                )

                let graphTables =
                    nativeGraph
                        .sheets[0]
                        .tables

                try Expect.true(
                    nativeGraph
                        .sheets[0]
                        .identifier
                        > 0,
                    "native-consolidated.sheet-identity"
                )

                try Expect.equal(
                    Set(
                        graphTables.map(
                            \.tableInfoIdentifier
                        )
                    )
                    .count,
                    2,
                    "native-consolidated.table-info-identities"
                )

                try Expect.equal(
                    Set(
                        graphTables.map(
                            \.tableModelIdentifier
                        )
                    )
                    .count,
                    2,
                    "native-consolidated.table-model-identities"
                )

                for table in graphTables {
                    try Expect.equal(
                        table.storage
                            .tableModelIdentifier,
                        table.tableModelIdentifier,
                        "native-consolidated.storage-identity"
                    )

                    try Expect.equal(
                        table.rowTileTree
                            .tableModelIdentifier,
                        table.tableModelIdentifier,
                        "native-consolidated.row-tree-identity"
                    )

                    try Expect.equal(
                        table.modernDataLists
                            .tableModelIdentifier,
                        table.tableModelIdentifier,
                        "native-consolidated-modern-format-identity"
                    )

                    if let formulas =
                        table.formulas
                    {
                        try Expect.equal(
                            formulas
                                .tableModelIdentifier,
                            table.tableModelIdentifier,
                            "native-consolidated.formula-identity"
                        )
                    }
                }

                let graphClients =
                    graphTables[0]

                let graphInvoices =
                    graphTables[1]

                try Expect.equal(
                    graphClients
                        .placedRows
                        .map(
                            \.globalRowIndex
                        ),
                    [
                        0,
                        1,
                        2,
                        3,
                    ],
                    "native-consolidated.clients-row-placement"
                )

                try Expect.equal(
                    graphInvoices
                        .placedRows
                        .map(
                            \.globalRowIndex
                        ),
                    [
                        0,
                        1,
                        2,
                        3,
                        4,
                    ],
                    "native-consolidated.invoices-row-placement"
                )

                try Expect.equal(
                    graphClients
                        .formulas?
                        .formulas
                        .count
                        ?? -1,
                    0,
                    "native-consolidated.clients-formulas"
                )

                try Expect.equal(
                    graphInvoices
                        .formulas?
                        .formulas
                        .count
                        ?? -1,
                    1,
                    "native-consolidated.invoices-formulas"
                )

                print(
                    "SWIFT CONSOLIDATED NATIVE GRAPH"
                )

                print(
                    "  archive reads per graph construction: 1"
                )

                print(
                    "  shared object stores per graph construction: 1"
                )

                print(
                    "  sheets: "
                    + String(
                        nativeGraph
                            .sheets
                            .count
                    )
                )

                print(
                    "  ordered tables: "
                    + graphTables
                        .map(
                            \.name
                        )
                        .joined(
                            separator: ", "
                        )
                )

                print(
                    "  table model identities: "
                    + graphTables
                        .map {
                            String(
                                $0.tableModelIdentifier
                            )
                        }
                        .joined(
                            separator: ", "
                        )
                )

                print(
                    "  identity joins: storage,rowTileTree,formulas,modernDataLists"
                )

                let canonicalFormulaCells =
                    snapshot
                        .sheets[0]
                        .tables[1]
                        .rows
                        .flatMap(
                            \.cells
                        )
                        .filter {
                            $0.formula != nil
                        }

                try Expect.equal(
                    canonicalFormulaCells.count,
                    3,
                    "native-snapshot-core.formula-presentation.canonical-count"
                )

                try Expect.equal(
                    canonicalFormulaCells.map(
                        \.format
                    ),
                    [
                        .automatic,
                        .automatic,
                        .automatic,
                    ],
                    "native-snapshot-core.formula-presentation.canonical-automatic"
                )

                let formulaStorageRecords =
                    graphInvoices
                        .placedRows
                        .flatMap {
                            $0.row.records
                        }
                        .filter {
                            $0.formulaKey != nil
                        }

                try Expect.equal(
                    formulaStorageRecords.count,
                    3,
                    "native-snapshot-core.formula-presentation.storage-count"
                )

                var storedFormulaFormats:
                    [NumbersCellFormat] = []

                for record in formulaStorageRecords {
                    try Expect.equal(
                        record.version,
                        UInt8(
                            5
                        ),
                        "native-snapshot-core.formula-presentation.version"
                    )

                    try Expect.equal(
                        record.type,
                        UInt8(
                            10
                        ),
                        "native-snapshot-core.formula-presentation.type"
                    )

                    try Expect.equal(
                        record.fieldMask,
                        UInt32(
                            0x0000_5201
                        ),
                        "native-snapshot-core.formula-presentation.mask"
                    )

                    try Expect.equal(
                        record.suggestedFormatKind,
                        Optional(
                            UInt32(
                                2
                            )
                        ),
                        "native-snapshot-core.formula-presentation.suggested-kind"
                    )

                    try Expect.equal(
                        record.formatFamily,
                        Optional(
                            NumbersNativeCellFormatFamily.currency
                        ),
                        "native-snapshot-core.formula-presentation.storage-family"
                    )

                    try Expect.equal(
                        record.controlCellSpecKey,
                        Optional<UInt32>.none,
                        "native-snapshot-core.formula-presentation.no-control"
                    )

                    try Expect.equal(
                        record.unparsedTrailingByteCount,
                        0,
                        "native-snapshot-core.formula-presentation.no-trailing-bytes"
                    )

                    storedFormulaFormats.append(
                        try NumbersPackageReader.resolvedCellFormat(
                            for:
                                record,
                            in:
                                graphInvoices.modernDataLists
                        )
                    )
                }

                try Expect.equal(
                    storedFormulaFormats,
                    [
                        .currency,
                        .currency,
                        .currency,
                    ],
                    "native-snapshot-core.formula-presentation.storage-result-currency"
                )

                print(
                    "SWIFT FORMULA PRESENTATION FORMAT"
                )

                print(
                    "  canonical public formats: "
                    + canonicalFormulaCells
                        .map {
                            $0.format.rawValue
                        }
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  stored result formats: "
                    + storedFormulaFormats
                        .map(
                            \.rawValue
                        )
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  BNC masks: "
                    + formulaStorageRecords
                        .map {
                            "0x"
                            + String(
                                $0.fieldMask,
                                radix:
                                    16
                            )
                        }
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  native snapshot presentation policy: characterized automatic"
                )

                let orderedCanonicalFormulaCells =
                    canonicalFormulaCells.sorted {
                        lhs,
                        rhs in

                        if lhs.row != rhs.row {
                            return lhs.row
                                < rhs.row
                        }

                        return lhs.column
                            < rhs.column
                    }

                try Expect.equal(
                    orderedCanonicalFormulaCells.count,
                    storedFormulaFormats.count,
                    "native-snapshot-core.formula-formatted.correlated-count"
                )

                print(
                    "SWIFT FORMULA FORMATTED VALUE"
                )

                print(
                    "  cells: "
                    + String(
                        orderedCanonicalFormulaCells.count
                    )
                )

                for (
                    index,
                    cell
                ) in orderedCanonicalFormulaCells.enumerated() {
                    guard
                        let formatted =
                            cell.formatted,
                        !formatted.isEmpty
                    else {
                        throw AppleNumbersError
                            .invalidSnapshotTransport(
                                "formula formatted-value characterization has no display string at \(cell.address)"
                            )
                    }

                    let scalarSignature =
                        formatted
                            .unicodeScalars
                            .map {
                                scalar in

                                let hexadecimal =
                                    String(
                                        scalar.value,
                                        radix:
                                            16,
                                        uppercase:
                                            true
                                    )

                                return
                                    "U+"
                                    + String(
                                        repeating:
                                            "0",
                                        count:
                                            max(
                                                0,
                                                4
                                                - hexadecimal.count
                                            )
                                    )
                                    + hexadecimal
                            }
                            .joined(
                                separator:
                                    " "
                            )

                    let storedFormat =
                        storedFormulaFormats[
                            index
                        ]

                    print(
                        "  "
                        + cell.address
                        + ": public="
                        + cell.format.rawValue
                        + " stored-result="
                        + storedFormat.rawValue
                    )

                    print(
                        "    formula: "
                        + (
                            cell.formula
                            ?? "<nil>"
                        )
                    )

                    print(
                        "    display: "
                        + formatted.debugDescription
                    )

                    print(
                        "    display-scalars: "
                        + scalarSignature
                    )
                }

                print(
                    "END SWIFT FORMULA FORMATTED VALUE"
                )

                let canonicalCore =
                    snapshotWithoutFormattedValues(
                        snapshot
                    )

                let nativeCore =
                    snapshotWithoutFormattedValues(
                        nativeSnapshot
                    )

                try Expect.equal(
                    nativeCore,
                    canonicalCore,
                    "native-snapshot-core.exact-parity-excluding-formatted"
                )

                try Expect.equal(
                    nativeSnapshot.name,
                    snapshot.name,
                    "native-snapshot-core.document-name"
                )

                try Expect.equal(
                    nativeSnapshot
                        .sheets
                        .map(
                            \.name
                        ),
                    snapshot
                        .sheets
                        .map(
                            \.name
                        ),
                    "native-snapshot-core.sheet-order"
                )

                try Expect.equal(
                    nativeSnapshot
                        .sheets
                        .flatMap(
                            \.tables
                        )
                        .map(
                            \.name
                        ),
                    snapshot
                        .sheets
                        .flatMap(
                            \.tables
                        )
                        .map(
                            \.name
                        ),
                    "native-snapshot-core.table-order"
                )

                let canonicalFormattedCount =
                    formattedValueCount(
                        snapshot
                    )

                let nativeFormattedCount =
                    formattedValueCount(
                        nativeSnapshot
                    )

                try Expect.true(
                    canonicalFormattedCount > 0,
                    "native-snapshot-core.canonical-formatted-values-exist"
                )

                try Expect.equal(
                    nativeFormattedCount,
                    canonicalFormattedCount,
                    "native-snapshot.formatted-count"
                )

                try Expect.equal(
                    nativeSnapshot,
                    snapshot,
                    "native-snapshot.full-parity"
                )

                print(
                    "SWIFT NATIVE SNAPSHOT CORE"
                )

                print(
                    "  document: "
                    + nativeSnapshot.name
                )

                print(
                    "  sheets: "
                    + String(
                        nativeSnapshot
                            .sheets
                            .count
                    )
                )

                print(
                    "  tables: "
                    + String(
                        nativeSnapshot
                            .sheets
                            .flatMap(
                                \.tables
                            )
                            .count
                    )
                )

                print(
                    "  cells: "
                    + String(
                        nativeSnapshot
                            .sheets
                            .flatMap(
                                \.tables
                            )
                            .flatMap(
                                \.rows
                            )
                            .flatMap(
                                \.cells
                            )
                            .count
                    )
                )

                print(
                    "  canonical formatted values: "
                    + String(
                        canonicalFormattedCount
                    )
                )

                print(
                    "  native formatted values: "
                    + String(
                        nativeFormattedCount
                    )
                )

                print(
                    "  core parity excluding formatted: true"
                )

                print(
                    "  full parity including formatted: true"
                )

                try Expect.equal(
                    snapshot.sheets.count,
                    1,
                    "native.sheet-count"
                )

                try Expect.equal(
                    snapshot.sheets[0].name,
                    "Probe",
                    "native.sheet-name"
                )

                try Expect.equal(
                    snapshot.sheets[0]
                        .tables
                        .map(
                            \.name
                        ),
                    [
                        "Clients",
                        "Invoices",
                    ],
                    "native.table-order"
                )

                let clients =
                    snapshot.sheets[0]
                        .tables[0]

                let invoices =
                    snapshot.sheets[0]
                        .tables[1]

                try proveNativePrimitiveParity(
                    snapshot: snapshot,
                    storage: nativeStorage
                )

                try characterizeNativeFormatReferences(
                    snapshot: snapshot,
                    storage: nativeStorage
                )

                try characterizeNativeFormatKeySpace(
                    snapshot: snapshot,
                    storage: nativeStorage,
                    formats: nativeFormats
                )

                try proveNativeFormulaCharacterization(
                    snapshot: snapshot,
                    storage: nativeStorage,
                    formulas: nativeFormulas
                )

                try Expect.equal(
                    clients.rowCount,
                    4,
                    "native.clients.row-count"
                )

                try Expect.equal(
                    clients.columnCount,
                    5,
                    "native.clients.column-count"
                )

                try Expect.equal(
                    clients.headerRowCount,
                    1,
                    "native.clients.header-row-count"
                )

                try Expect.equal(
                    invoices.footerRowCount,
                    1,
                    "native.invoices.footer-row-count"
                )

                try Expect.equal(
                    clients.rows[1]
                        .cells[0]
                        .value,
                    .number(
                        100
                    ),
                    "native.number"
                )

                try Expect.equal(
                    clients.rows[1]
                        .cells[2]
                        .value,
                    .boolean(
                        true
                    ),
                    "native.boolean"
                )

                try Expect.equal(
                    clients.rows[2]
                        .cells[3]
                        .value,
                    .empty,
                    "native.empty"
                )

                try Expect.equal(
                    invoices.rows[1]
                        .cells[2]
                        .format,
                    .currency,
                    "native.currency-format"
                )

                let formulaCell =
                    invoices.rows[1]
                        .cells[3]

                try Expect.equal(
                    formulaCell.value,
                    .number(
                        251
                    ),
                    "native.formula.calculated-value"
                )

                try Expect.true(
                    formulaCell.formula?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .hasPrefix(
                            "="
                        )
                    ?? false,
                    "native.formula.source"
                )

                let createdAt =
                    clients.rows[1]
                        .cells[4]

                try Expect.equal(
                    createdAt.format,
                    .dateAndTime,
                    "native.date-format"
                )

                try Expect.true(
                    isDate(
                        createdAt.value
                    ),
                    "native.date-value"
                )

                let repeatedSnapshot =
                    try AppleNumbers.snapshot(
                        at: documentURL
                    )

                try Expect.equal(
                    repeatedSnapshot,
                    snapshot,
                    "native.snapshot.repeated-extraction"
                )

                let schema =
                    NumbersSchema(
                        inferring: snapshot
                    )

                try Expect.equal(
                    schema.models.count,
                    2,
                    "native.schema.model-count"
                )

                try Expect.equal(
                    schema.relationships.count,
                    1,
                    "native.schema.relationship-count"
                )

                try Expect.equal(
                    schema.relationships[0]
                        .cardinality,
                    .manyToOne,
                    "native.schema.relationship-cardinality"
                )

                try Expect.equal(
                    schema.relationships[0]
                        .evidence
                        .coverage,
                    1,
                    "native.schema.relationship-coverage"
                )
            }
        }
    }
}

private func snapshotWithoutFormattedValues(
    _ snapshot: NumbersSnapshot
) -> NumbersSnapshot {
    NumbersSnapshot(
        name:
            snapshot.name,
        sheets:
            snapshot
                .sheets
                .map {
                    sheet in

                    NumbersSheetSnapshot(
                        index:
                            sheet.index,
                        name:
                            sheet.name,
                        tables:
                            sheet
                                .tables
                                .map {
                                    table in

                                    NumbersTableSnapshot(
                                        index:
                                            table.index,
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
                                            table
                                                .rows
                                                .map {
                                                    row in

                                                    NumbersRowSnapshot(
                                                        index:
                                                            row.index,
                                                        cells:
                                                            row
                                                                .cells
                                                                .map {
                                                                    cell in

                                                                    NumbersCellSnapshot(
                                                                        row:
                                                                            cell.row,
                                                                        column:
                                                                            cell.column,
                                                                        address:
                                                                            cell.address,
                                                                        value:
                                                                            cell.value,
                                                                        format:
                                                                            cell.format,
                                                                        formula:
                                                                            cell.formula,
                                                                        formatted:
                                                                            nil
                                                                    )
                                                                }
                                                    )
                                                }
                                    )
                                }
                    )
                }
    )
}

private func formattedValueCount(
    _ snapshot: NumbersSnapshot
) -> Int {
    snapshot
        .sheets
        .flatMap(
            \.tables
        )
        .flatMap(
            \.rows
        )
        .flatMap(
            \.cells
        )
        .filter {
            $0.formatted != nil
        }
        .count
}

private func isDate(
    _ value: NumbersCellValue
) -> Bool {
    if case .date = value {
        return true
    }

    return false
}

func createNumbersFixture(
    at documentURL: URL
) throws {
    let script = #"""
on run argv
    if (count of argv) is not 1 then
        error "Expected one destination path"
    end if

    set destinationFile to POSIX file (item 1 of argv)
    set fixtureDate to current date

    tell application "Numbers"
        set fixtureDocument to make new document
        save fixtureDocument in destinationFile

        tell fixtureDocument
            tell active sheet
                set its name to "Probe"

                set existingTables to every table

                repeat with existingTable in existingTables
                    delete existingTable
                end repeat

                set clientsTable to make new table with properties ¬
                    {name:"Clients", row count:4, column count:5, ¬
                        header row count:1, header column count:0, ¬
                        footer row count:0}

                tell clientsTable
                    set value of cell 1 of row 1 to "client_id"
                    set value of cell 2 of row 1 to "name"
                    set value of cell 3 of row 1 to "active"
                    set value of cell 4 of row 1 to "note"
                    set value of cell 5 of row 1 to "created_at"

                    set value of cell 1 of row 2 to 100
                    set value of cell 2 of row 2 to "Ada"
                    set format of cell 3 of row 2 to checkbox
                    set value of cell 3 of row 2 to true
                    set value of cell 4 of row 2 to "first"
                    set format of cell 5 of row 2 to date and time
                    set value of cell 5 of row 2 to fixtureDate

                    set value of cell 1 of row 3 to 101
                    set value of cell 2 of row 3 to "Ben"
                    set format of cell 3 of row 3 to checkbox
                    set value of cell 3 of row 3 to false
                    set format of cell 5 of row 3 to date and time
                    set value of cell 5 of row 3 to fixtureDate

                    set value of cell 1 of row 4 to 102
                    set value of cell 2 of row 4 to "Cleo"
                    set format of cell 3 of row 4 to checkbox
                    set value of cell 3 of row 4 to true
                    set value of cell 4 of row 4 to "third"
                    set format of cell 5 of row 4 to date and time
                    set value of cell 5 of row 4 to fixtureDate
                end tell

                set invoicesTable to make new table with properties ¬
                    {name:"Invoices", row count:5, column count:4, ¬
                        header row count:1, header column count:0, ¬
                        footer row count:1}

                tell invoicesTable
                    set value of cell 1 of row 1 to "invoice_id"
                    set value of cell 2 of row 1 to "client_id"
                    set value of cell 3 of row 1 to "amount"
                    set value of cell 4 of row 1 to "double_amount"

                    set value of cell 1 of row 2 to 9001
                    set value of cell 2 of row 2 to 100
                    set value of cell 3 of row 2 to 125.50
                    set format of cell 3 of row 2 to currency
                    set value of cell 4 of row 2 to "=C2*2"

                    set value of cell 1 of row 3 to 9002
                    set value of cell 2 of row 3 to 100
                    set value of cell 3 of row 3 to 200
                    set format of cell 3 of row 3 to currency
                    set value of cell 4 of row 3 to "=C3*2"

                    set value of cell 1 of row 4 to 9003
                    set value of cell 2 of row 4 to 102
                    set value of cell 3 of row 4 to 95.25
                    set format of cell 3 of row 4 to currency
                    set value of cell 4 of row 4 to "=C4*2"

                    set value of cell 3 of row 5 to "TOTAL"
                end tell
            end tell
        end tell

        save fixtureDocument in destinationFile
        close fixtureDocument saving no
    end tell
end run
"""#

    let scriptURL =
        documentURL
            .deletingLastPathComponent()
            .appendingPathComponent(
                "fixture.applescript"
            )

    try script.write(
        to: scriptURL,
        atomically: true,
        encoding: .utf8
    )

    let stderr = Pipe()

    let process = Process()

    process.executableURL = URL(
        fileURLWithPath:
            "/usr/bin/osascript"
    )

    process.arguments = [
        scriptURL.path,
        documentURL.path,
    ]

    process.standardOutput =
        FileHandle.nullDevice

    process.standardError =
        stderr

    try process.run()

    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let data =
            stderr
                .fileHandleForReading
                .readDataToEndOfFile()

        throw AppleNumbersError.scriptFailed(
            status:
                process.terminationStatus,
            stderr:
                String(
                    data: data,
                    encoding: .utf8
                )
                ?? "<non-UTF8 fixture stderr>"
        )
    }
}
