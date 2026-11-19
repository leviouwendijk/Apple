@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeRowPlacementFlow:
        TestFlow
    {
        TestFlow(
            "numbers-native-row-placement",
            tags: [
                "numbers",
                "native",
                "tile",
                "row-tree",
                "multi-tile",
                "integration",
            ]
        ) {
            Step(
                "rowTileTree places sparse tile-local markers into exact global rows"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix:
                            "RowPlacement"
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
                            "Row-Placement.numbers"
                        )

                print(
                    "ROW PLACEMENT: creating sparse 520-row fixture"
                )

                try createNumbersRowPlacementFixture(
                    at: documentURL
                )

                print(
                    "ROW PLACEMENT: fixture saved; decoding native storage"
                )

                let storage =
                    try NumbersPackageReader.storageProfile(
                        at: documentURL
                    )

                print(
                    "ROW PLACEMENT: decoding DataStore rowTileTree"
                )

                let rowTrees =
                    try NumbersPackageReader.rowTileTreeProfile(
                        at: documentURL
                    )

                try proveNativeGlobalRowPlacement(
                    storage:
                        storage,
                    rowTrees:
                        rowTrees
                )
            }
        }
    }
}

private let rowPlacementFixtureRowCount =
    520

private let rowPlacementMarkerRows:
    [Int] =
        [
            1,
            255,
            256,
            257,
            511,
            512,
            513,
            520,
        ]

private func proveNativeGlobalRowPlacement(
    storage: NumbersNativeTableStorageProfile,
    rowTrees: NumbersNativeRowTileTreeProfile
) throws {
    guard let storageTable =
        storage.tables.first(
            where: {
                $0.name == "Rows"
            }
        )
    else {
        throw AppleNumbersError
            .invalidSnapshotTransport(
                "sparse multi-tile fixture native Rows storage missing"
            )
    }

    guard let rowTree =
        rowTrees.tables.first(
            where: {
                $0.name == "Rows"
            }
        )
    else {
        throw AppleNumbersError
            .invalidSnapshotTransport(
                "sparse multi-tile fixture Rows rowTileTree missing"
            )
    }

    try Expect.true(
        storageTable.tiles.count > 1,
        "native-row-placement.multiple-tiles"
    )

    try Expect.true(
        rowTree.nodes.count > 1,
        "native-row-placement.multiple-row-tree-nodes"
    )

    try Expect.equal(
        rowTree.tileLinks.count,
        storageTable.tiles.count,
        "native-row-placement.tile-link-count"
    )

    let placedRows =
        try storageTable.placedRows(
            using:
                rowTree
        )

    try Expect.equal(
        placedRows.count,
        rowPlacementMarkerRows.count,
        "native-row-placement.sparse-placed-row-count"
    )

    let expectedMarkers =
        Set(
            rowPlacementMarkerRows
        )

    var seenMarkers:
        Set<Int> = []

    var tileIndexes:
        Set<Int> = []

    var tileBases:
        Set<Int> = []

    var markerMatches =
        0

    for placed in placedRows {
        let oneBasedRow =
            placed.globalRowIndex
            + 1

        guard expectedMarkers.contains(
            oneBasedRow
        ) else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native sparse fixture unexpectedly stored global row \(oneBasedRow)"
                )
        }

        guard let nativeRecord =
            placed.row.records.first(
                where: {
                    $0.columnIndex == 0
                }
            )
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native sparse marker row \(oneBasedRow) has no column-1 record"
                )
        }

        guard let nativeValue =
            nativeRecord.primitiveValue
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native sparse marker row \(oneBasedRow) has no primitive value"
                )
        }

        let expectedValue:
            NumbersCellValue =
                .number(
                    Decimal(
                        oneBasedRow
                    )
                )

        try Expect.equal(
            nativeValue,
            expectedValue,
            "native-row-placement.marker-value-\(oneBasedRow)"
        )

        guard seenMarkers.insert(
            oneBasedRow
        )
        .inserted else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native sparse marker row \(oneBasedRow) resolved more than once"
                )
        }

        tileIndexes.insert(
            placed.tileArrayIndex
        )

        tileBases.insert(
            placed.tileBaseRowIndex
        )

        markerMatches +=
            1
    }

    try Expect.true(
        seenMarkers == expectedMarkers,
        "native-row-placement.exact-marker-set"
    )

    try Expect.equal(
        markerMatches,
        rowPlacementMarkerRows.count,
        "native-row-placement.marker-match-count"
    )

    try Expect.true(
        tileIndexes.count > 1,
        "native-row-placement.markers-span-multiple-tiles"
    )

    try Expect.true(
        tileBases.count > 1,
        "native-row-placement.markers-span-multiple-row-bases"
    )

    let sortedNodes =
        rowTree.nodes.sorted {
            lhs,
            rhs in

            lhs.key
                < rhs.key
        }

    print(
        "SWIFT ROW TILE TREE"
    )

    print(
        "  logical rows: "
        + String(
            rowPlacementFixtureRowCount
        )
    )

    print(
        "  populated marker rows: "
        + String(
            rowPlacementMarkerRows.count
        )
    )

    print(
        "  TileStorage entries: "
        + String(
            rowTree.tileLinks.count
        )
    )

    print(
        "  decoded tiles: "
        + String(
            storageTable.tiles.count
        )
    )

    print(
        "  row-tree nodes: "
        + String(
            rowTree.nodes.count
        )
    )

    print(
        "  TileStorage fields: "
        + rowTree
            .tileStorageFieldSignatures
            .joined(
                separator:
                    ","
            )
    )

    print(
        "  rowTileTree fields: "
        + rowTree
            .rowTileTreeFieldSignatures
            .joined(
                separator:
                    ","
            )
    )

    print(
        "  ROW TREE NODES"
    )

    for node in sortedNodes {
        var line =
            "    key="
            + String(
                node.key
            )

        line +=
            " value="
            + String(
                node.value
            )

        if
            node.value >= 0,
            node.value
                < rowTree.tileLinks.count
        {
            let link =
                rowTree.tileLinks[
                    node.value
                ]

            line +=
                " tileID="
                + String(
                    link.tileID
                )

            line +=
                " object="
                + String(
                    link.objectIdentifier
                )
        }

        if
            node.value >= 0,
            node.value
                < storageTable.tiles.count
        {
            let tile =
                storageTable.tiles[
                    node.value
                ]

            line +=
                " storedRows="
                + String(
                    tile.rows.count
                )

            line +=
                " maxRow="
                + String(
                    describing:
                        tile.maxRow
                )
        }

        line +=
            " fields="
            + node
                .fieldSignatures
                .joined(
                    separator:
                        ","
                )

        print(
            line
        )
    }

    print(
        "SWIFT GLOBAL ROW PLACEMENT"
    )

    print(
        "  marker matches: "
        + String(
            markerMatches
        )
        + "/"
        + String(
            rowPlacementMarkerRows.count
        )
    )

    print(
        "  marker tile indexes: "
        + tileIndexes
            .sorted()
            .map {
                String(
                    $0
                )
            }
            .joined(
                separator:
                    ","
            )
    )

    print(
        "  marker base rows: "
        + tileBases
            .sorted()
            .map {
                String(
                    $0
                )
            }
            .joined(
                separator:
                    ","
            )
    )

    print(
        "  BOUNDARY MARKERS"
    )

    for oneBasedRow in
        rowPlacementMarkerRows
    {
        guard let placed =
            placedRows.first(
                where: {
                    $0.globalRowIndex
                        == oneBasedRow - 1
                }
            )
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native sparse boundary marker \(oneBasedRow) was not placed"
                )
        }

        print(
            "    row="
            + String(
                oneBasedRow
            )
            + " global="
            + String(
                placed.globalRowIndex
            )
            + " base="
            + String(
                placed.tileBaseRowIndex
            )
            + " tileArrayIndex="
            + String(
                placed.tileArrayIndex
            )
            + " tileID="
            + String(
                placed.tileID
            )
            + " tileRowIndex="
            + String(
                placed.tileRowIndex
            )
        )
    }
}

private func createNumbersRowPlacementFixture(
    at documentURL: URL
) throws {
    let script = #"""
on run argv
    if (count of argv) is not 1 then
        error "Expected one destination path"
    end if

    set destinationFile to POSIX file (item 1 of argv)

    tell application "Numbers"
        set fixtureDocument to make new document
        save fixtureDocument in destinationFile

        tell fixtureDocument
            tell active sheet
                set its name to "Row Placement"

                set existingTables to every table

                repeat with existingTable in existingTables
                    delete existingTable
                end repeat

                set rowTable to make new table with properties ¬
                    {name:"Rows", row count:520, column count:2, ¬
                        header row count:0, header column count:0, ¬
                        footer row count:0}

                tell rowTable
                    set value of cell 1 of row 1 to 1
                    set value of cell 1 of row 255 to 255
                    set value of cell 1 of row 256 to 256
                    set value of cell 1 of row 257 to 257
                    set value of cell 1 of row 511 to 511
                    set value of cell 1 of row 512 to 512
                    set value of cell 1 of row 513 to 513
                    set value of cell 1 of row 520 to 520
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
                "row-placement.applescript"
            )

    try script.write(
        to: scriptURL,
        atomically: true,
        encoding: .utf8
    )

    let stderr =
        Pipe()

    let process =
        Process()

    process.executableURL =
        URL(
            fileURLWithPath:
                "/usr/bin/osascript"
        )

    process.arguments =
        [
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
                    data:
                        data,
                    encoding:
                        .utf8
                )
                ?? "<non-UTF8 row-placement stderr>"
        )
    }
}
