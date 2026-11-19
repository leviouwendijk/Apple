@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeComprehensiveSnapshotFlow:
        TestFlow
    {
        TestFlow(
            "numbers-native-comprehensive-snapshot",
            tags: [
                "numbers",
                "native",
                "snapshot",
                "integration",
                "multi-sheet",
                "multi-table",
                "multi-tile",
                "wide-offset",
                "format",
                "formula",
            ]
        ) {
            Step(
                "one comprehensive Numbers document preserves exact native/JXA snapshot semantics"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix:
                            "ComprehensiveSnapshot"
                    )

                defer {
                    try? FileManager.default
                        .removeItem(
                            at:
                                directory
                        )
                }

                let documentURL =
                    directory
                        .appendingPathComponent(
                            "Comprehensive-Native-Probe.numbers"
                        )

                print(
                    "COMPREHENSIVE: creating fixture"
                )

                try createNumbersComprehensiveSnapshotFixture(
                    at:
                        documentURL
                )

                print(
                    "COMPREHENSIVE: fixture saved"
                )

                print(
                    "COMPREHENSIVE: extracting JXA canonical snapshot"
                )

                let canonical =
                    try AppleNumbers.snapshot(
                        at:
                            documentURL
                    )

                print(
                    "COMPREHENSIVE: canonical snapshot complete"
                )

                print(
                    "COMPREHENSIVE: extracting native snapshot"
                )

                let native =
                    try NumbersPackageReader.nativeSnapshot(
                        at:
                            documentURL
                    )

                print(
                    "COMPREHENSIVE: native snapshot complete"
                )

                print(
                    "COMPREHENSIVE: proving parity"
                )

                try Expect.equal(
                    canonical.sheets.map(
                        \.name
                    ),
                    [
                        "Core",
                        "Formats",
                        "Wide",
                    ],
                    "native-comprehensive.sheet-order"
                )

                try Expect.equal(
                    native,
                    canonical,
                    "native-comprehensive.full-parity"
                )

                print(
                    "COMPREHENSIVE: parity proved"
                )

                guard
                    canonical.sheets.count == 3,
                    let coreSheet =
                        canonical.sheets.first(
                            where: {
                                $0.name == "Core"
                            }
                        ),
                    let formatsSheet =
                        canonical.sheets.first(
                            where: {
                                $0.name == "Formats"
                            }
                        ),
                    let wideSheet =
                        canonical.sheets.first(
                            where: {
                                $0.name == "Wide"
                            }
                        )
                else {
                    throw AppleNumbersError
                        .invalidSnapshotTransport(
                            "comprehensive fixture missing expected sheets"
                        )
                }

                try Expect.equal(
                    coreSheet.tables.map(
                        \.name
                    ),
                    [
                        "Orders",
                        "Sparse",
                    ],
                    "native-comprehensive.core-table-order"
                )

                try Expect.equal(
                    formatsSheet.tables.map(
                        \.name
                    ),
                    [
                        "Formats",
                    ],
                    "native-comprehensive.formats-table-order"
                )

                try Expect.equal(
                    wideSheet.tables.map(
                        \.name
                    ),
                    [
                        "Wide",
                    ],
                    "native-comprehensive.wide-table-order"
                )

                guard
                    let ordersTable =
                        coreSheet.tables.first(
                            where: {
                                $0.name == "Orders"
                            }
                        ),
                    let sparseTable =
                        coreSheet.tables.first(
                            where: {
                                $0.name == "Sparse"
                            }
                        ),
                    let formatsTable =
                        formatsSheet.tables.first(
                            where: {
                                $0.name == "Formats"
                            }
                        ),
                    let wideTable =
                        wideSheet.tables.first(
                            where: {
                                $0.name == "Wide"
                            }
                        )
                else {
                    throw AppleNumbersError
                        .invalidSnapshotTransport(
                            "comprehensive fixture missing expected tables"
                        )
                }

                try Expect.equal(
                    ordersTable.rowCount,
                    6,
                    "native-comprehensive.orders.rows"
                )

                try Expect.equal(
                    ordersTable.columnCount,
                    6,
                    "native-comprehensive.orders.columns"
                )

                try Expect.equal(
                    ordersTable.headerRowCount,
                    1,
                    "native-comprehensive.orders.header-rows"
                )

                try Expect.equal(
                    ordersTable.footerRowCount,
                    1,
                    "native-comprehensive.orders.footer-rows"
                )

                try Expect.equal(
                    sparseTable.rowCount,
                    520,
                    "native-comprehensive.sparse.rows"
                )

                try Expect.equal(
                    sparseTable.columnCount,
                    2,
                    "native-comprehensive.sparse.columns"
                )

                try Expect.equal(
                    formatsTable.rowCount,
                    16,
                    "native-comprehensive.formats.rows"
                )

                try Expect.equal(
                    formatsTable.columnCount,
                    2,
                    "native-comprehensive.formats.columns"
                )

                try Expect.equal(
                    formatsTable.headerRowCount,
                    1,
                    "native-comprehensive.formats.header-rows"
                )

                try Expect.equal(
                    wideTable.rowCount,
                    2,
                    "native-comprehensive.wide.rows"
                )

                try Expect.equal(
                    wideTable.columnCount,
                    300,
                    "native-comprehensive.wide.columns"
                )

                let formulaCells =
                    canonical.sheets.flatMap {
                        $0.tables
                    }
                    .flatMap {
                        $0.rows
                    }
                    .flatMap {
                        $0.cells
                    }
                    .filter {
                        $0.formula != nil
                    }

                try Expect.equal(
                    formulaCells.count,
                    3,
                    "native-comprehensive.formula-count"
                )

                let totalCells =
                    canonical.sheets
                        .flatMap {
                            $0.tables
                        }
                        .reduce(
                            0
                        ) {
                            result,
                            table in

                            result
                            + (
                                table.rowCount
                                * table.columnCount
                            )
                        }

                try Expect.equal(
                    totalCells,
                    1708,
                    "native-comprehensive.cell-count"
                )

                print(
                    "SWIFT COMPREHENSIVE NATIVE SNAPSHOT"
                )

                print(
                    "  document: "
                    + canonical.name
                )

                print(
                    "  sheets: "
                    + String(
                        canonical.sheets.count
                    )
                )

                print(
                    "  ordered sheets: "
                    + canonical.sheets
                        .map(
                            \.name
                        )
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  tables: "
                    + String(
                        canonical.sheets
                            .reduce(
                                0
                            ) {
                                $0
                                + $1.tables.count
                            }
                    )
                )

                print(
                    "  Core tables: "
                    + coreSheet.tables
                        .map(
                            \.name
                        )
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  Formats tables: "
                    + formatsSheet.tables
                        .map(
                            \.name
                        )
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  Wide tables: "
                    + wideSheet.tables
                        .map(
                            \.name
                        )
                        .joined(
                            separator:
                                ", "
                        )
                )

                print(
                    "  cells: "
                    + String(
                        totalCells
                    )
                )

                print(
                    "  sparse rows: "
                    + String(
                        sparseTable.rowCount
                    )
                )

                print(
                    "  wide columns: "
                    + String(
                        wideTable.columnCount
                    )
                )

                print(
                    "  formula cells: "
                    + String(
                        formulaCells.count
                    )
                )

                print(
                    "  characterized format cases: 15"
                )

                print(
                    "  full parity including formatted: true"
                )

                print(
                    "END SWIFT COMPREHENSIVE NATIVE SNAPSHOT"
                )
            }
        }
    }
}

private func createNumbersComprehensiveSnapshotFixture(
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
        set theseFormats to {automatic, checkbox, currency, date and time, fraction, number, percent, pop up menu, scientific, slider, stepper, text, duration, rating, numeral system}

        set formatLabels to {"automatic", "checkbox", "currency", "date and time", "fraction", "number", "percent", "pop up menu", "scientific", "slider", "stepper", "text", "duration", "rating", "numeral system"}

        set formatData to {42.5, true, 1234.02, fixtureDate, 0.1, 123.89, 0.75, "", 64, 64, 35, "HOWDY", 4.5, 3, 4569.123}

        set fixtureDocument to make new document
        save fixtureDocument in destinationFile

        tell fixtureDocument
            set coreSheet to active sheet

            tell coreSheet
                set its name to "Core"

                set existingTables to every table

                repeat with existingTable in existingTables
                    delete existingTable
                end repeat

                set ordersTable to make new table with properties ¬
                    {name:"Orders", row count:6, column count:6, ¬
                        header row count:1, header column count:0, ¬
                        footer row count:1}

                tell ordersTable
                    set value of cell 1 of row 1 to "order_id"
                    set value of cell 2 of row 1 to "label"
                    set value of cell 3 of row 1 to "amount"
                    set value of cell 4 of row 1 to "double_amount"
                    set value of cell 5 of row 1 to "active"
                    set value of cell 6 of row 1 to "created_at"

                    set value of cell 1 of row 2 to 1001
                    set value of cell 2 of row 2 to "Alpha"
                    set value of cell 3 of row 2 to 125.5
                    set format of cell 3 of row 2 to currency
                    set value of cell 4 of row 2 to "=C2*2"
                    set value of cell 5 of row 2 to true
                    set format of cell 5 of row 2 to checkbox
                    set value of cell 6 of row 2 to fixtureDate
                    set format of cell 6 of row 2 to date and time

                    set value of cell 1 of row 3 to 1002
                    set value of cell 2 of row 3 to "Beta"
                    set value of cell 3 of row 3 to 200
                    set format of cell 3 of row 3 to currency
                    set value of cell 4 of row 3 to "=C3*2"
                    set value of cell 5 of row 3 to false
                    set format of cell 5 of row 3 to checkbox
                    set value of cell 6 of row 3 to fixtureDate
                    set format of cell 6 of row 3 to date and time

                    set value of cell 1 of row 4 to 1003
                    set value of cell 2 of row 4 to "Gamma"
                    set value of cell 3 of row 4 to 95.25
                    set format of cell 3 of row 4 to currency
                    set value of cell 4 of row 4 to "=C4*2"
                    set value of cell 5 of row 4 to true
                    set format of cell 5 of row 4 to checkbox
                    set value of cell 6 of row 4 to fixtureDate
                    set format of cell 6 of row 4 to date and time

                    set value of cell 1 of row 5 to 1004
                    set value of cell 2 of row 5 to "Intentionally sparse"

                    set value of cell 1 of row 6 to "TOTAL"
                end tell

                set sparseTable to make new table with properties ¬
                    {name:"Sparse", row count:520, column count:2, ¬
                        header row count:0, header column count:0, ¬
                        footer row count:0}

                tell sparseTable
                    set value of cell 1 of row 1 to 1
                    set value of cell 1 of row 255 to 255
                    set value of cell 1 of row 256 to 256
                    set value of cell 1 of row 257 to 257
                    set value of cell 1 of row 511 to 511
                    set value of cell 1 of row 512 to 512
                    set value of cell 1 of row 513 to 513
                    set value of cell 1 of row 520 to 520

                    set value of cell 2 of row 1 to "first"
                    set value of cell 2 of row 257 to "second tile"
                    set value of cell 2 of row 513 to "third tile"
                    set value of cell 2 of row 520 to "last"
                end tell
            end tell

            set formatsSheet to make new sheet at end of sheets with properties ¬
                {name:"Formats"}

            tell formatsSheet
                set formatExistingTables to every table

                repeat with existingFormatTable in formatExistingTables
                    delete existingFormatTable
                end repeat

                set formatTable to make new table with properties ¬
                    {name:"Formats", row count:16, column count:2, ¬
                        header row count:1, header column count:0, ¬
                        footer row count:0}

                tell formatTable
                    set value of cell 1 of row 1 to "requested_format"
                    set value of cell 2 of row 1 to "value"

                    repeat with i from 1 to count of theseFormats
                        set targetRow to i + 1

                        set value of cell 1 of row targetRow ¬
                            to item i of formatLabels

                        set value of cell 2 of row targetRow ¬
                            to item i of formatData

                        set format of cell 2 of row targetRow ¬
                            to item i of theseFormats
                    end repeat
                end tell
            end tell

            set wideSheet to make new sheet at end of sheets with properties ¬
                {name:"Wide"}

            tell wideSheet
                set wideExistingTables to every table

                repeat with existingWideTable in wideExistingTables
                    delete existingWideTable
                end repeat

                set wideTable to make new table with properties ¬
                    {name:"Wide", row count:2, column count:300, ¬
                        header row count:0, header column count:0, ¬
                        footer row count:0}

                tell wideTable
                    repeat with columnIndex from 1 to 300
                        set value of cell columnIndex of row 1 ¬
                            to columnIndex
                    end repeat

                    set value of cell 1 of row 2 to "wide-row-tail"
                    set value of cell 300 of row 2 to 300
                end tell
            end tell
        end tell

        save fixtureDocument
        close fixtureDocument saving no
    end tell
end run
"""#

    let process =
        Process()

    let standardInput =
        Pipe()

    let standardError =
        Pipe()

    process.executableURL =
        URL(
            fileURLWithPath:
                "/usr/bin/osascript"
        )

    process.arguments = [
        "-",
        documentURL.path,
    ]

    process.standardInput =
        standardInput

    process.standardError =
        standardError

    try process.run()

    standardInput.fileHandleForWriting.write(
        Data(
            script.utf8
        )
    )

    try standardInput.fileHandleForWriting.close()

    process.waitUntilExit()

    let errorData =
        standardError.fileHandleForReading
            .readDataToEndOfFile()

    guard process.terminationStatus == 0 else {
        throw AppleNumbersError.scriptFailed(
            status:
                process.terminationStatus,
            stderr:
                String(
                    data:
                        errorData,
                    encoding:
                        .utf8
                )
                ?? ""
        )
    }
}
