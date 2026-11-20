@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeWideOffsetFlow:
        TestFlow
    {
        TestFlow(
            "numbers-native-wide-offset",
            tags: [
                "numbers",
                "native",
                "iwa",
                "table",
                "tile",
                "storage",
                "wide-offset",
            ]
        ) {
            Step(
                "Swift decodes wide-row UInt16 offsets with characterized four-byte units and preserves canonical parity"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix: "WideOffsetFlow"
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
                            "Wide-Offset-Probe.numbers"
                        )

                try createNumbersWideOffsetFixture(
                    at: documentURL
                )

                let profile =
                    try NumbersPackageReader
                        .wideOffsetProfile(
                            at: documentURL
                        )

                let populatedRows =
                    profile.tiles.flatMap {
                        tile in

                        tile.rows
                            .filter {
                                $0.cellCount > 0
                            }
                            .map {
                                row in

                                (
                                    tile:
                                        tile,
                                    row:
                                        row
                                )
                            }
                    }

                let wideRows =
                    populatedRows.filter {
                        $0.row.hasWideOffsets == true
                    }

                let tableStorageFlags =
                    Set(
                        profile.tableStorages.map {
                            wideFlagDescription(
                                $0.shouldUseWideRows
                            )
                        }
                    )
                    .sorted()

                let tileFlags =
                    Set(
                        profile.tiles.map {
                            wideFlagDescription(
                                $0.shouldUseWideRows
                            )
                        }
                    )
                    .sorted()

                let rowFlags =
                    Set(
                        populatedRows.map {
                            wideFlagDescription(
                                $0.row.hasWideOffsets
                            )
                        }
                    )
                    .sorted()

                var characterizedUInt16WideRows =
                    0

                print(
                    "SWIFT WIDE OFFSET CHARACTERIZATION"
                )

                print(
                    "  table storages: "
                    + String(
                        profile.tableStorages.count
                    )
                )

                print(
                    "  tiles: "
                    + String(
                        profile.tiles.count
                    )
                )

                print(
                    "  populated rows: "
                    + String(
                        populatedRows.count
                    )
                )

                print(
                    "  wide rows: "
                    + String(
                        wideRows.count
                    )
                )

                print(
                    "  TileStorage.should_use_wide_rows: "
                    + tableStorageFlags.joined(
                        separator: ", "
                    )
                )

                print(
                    "  Tile.should_use_wide_rows: "
                    + tileFlags.joined(
                        separator: ", "
                    )
                )

                print(
                    "  TileRowInfo.has_wide_offsets: "
                    + rowFlags.joined(
                        separator: ", "
                    )
                )

                for item in populatedRows {
                    let tile =
                        item.tile

                    let row =
                        item.row

                    let uint16Candidate =
                        offsetCandidateAnalysis(
                            bytes:
                                row.cellOffsets,
                            width:
                                2,
                            storageByteCount:
                                row.cellStorageByteCount
                        )

                    let uint32Candidate =
                        offsetCandidateAnalysis(
                            bytes:
                                row.cellOffsets,
                            width:
                                4,
                            storageByteCount:
                                row.cellStorageByteCount
                        )

                    if row.hasWideOffsets == true {
                        let uint16Matches =
                            uint16Candidate?.slotCount
                            == row.cellCount
                            && uint16Candidate?.presentCount
                            == row.cellCount
                            && uint16Candidate?.allPresentOffsetsInBounds
                            == true
                            && uint16Candidate?.uniquePresentOffsets
                            == true

                        let uint32Matches =
                            uint32Candidate?.slotCount
                            == row.cellCount
                            && uint32Candidate?.presentCount
                            == row.cellCount
                            && uint32Candidate?.allPresentOffsetsInBounds
                            == true
                            && uint32Candidate?.uniquePresentOffsets
                            == true

                        if
                            uint16Matches,
                            !uint32Matches
                        {
                            characterizedUInt16WideRows += 1
                        }
                    }

                    var line =
                        "  row tile="
                        + String(
                            tile.objectIdentifier
                        )

                    line +=
                        " maxColumn="
                        + String(
                            tile.maxColumn
                        )

                    line +=
                        " tileRowIndex="
                        + String(
                            row.tileRowIndex
                        )

                    line +=
                        " cells="
                        + String(
                            row.cellCount
                        )

                    line +=
                        " storageBytes="
                        + String(
                            row.cellStorageByteCount
                        )

                    line +=
                        " offsetBytes="
                        + String(
                            row.cellOffsetsByteCount
                        )

                    line +=
                        " hasWideOffsets="
                        + wideFlagDescription(
                            row.hasWideOffsets
                        )

                    line +=
                        " uint16Candidate="
                        + offsetCandidateDescription(
                            uint16Candidate
                        )

                    line +=
                        " uint32Candidate="
                        + offsetCandidateDescription(
                            uint32Candidate
                        )

                    print(
                        line
                    )
                }

                try Expect.true(
                    !wideRows.isEmpty,
                    "wide-offset.fixture-produced-wide-row"
                )

                try Expect.equal(
                    characterizedUInt16WideRows,
                    wideRows.count,
                    "wide-offset.uint16-layout-characterized"
                )

                try Expect.equal(
                    wideRows.count,
                    1,
                    "wide-offset.single-wide-row"
                )

                let wideRow =
                    wideRows[0]
                        .row

                try Expect.equal(
                    wideRow.cellStorage.count,
                    wideRow.cellStorageByteCount,
                    "wide-offset.raw-storage-byte-count"
                )

                let scaleCandidates =
                    [
                        1,
                        2,
                        4,
                        8,
                    ]
                    .map {
                        offsetScaleAnalysis(
                            bytes:
                                wideRow.cellOffsets,
                            storage:
                                wideRow.cellStorage,
                            scale:
                                $0
                        )
                    }

                print(
                    "SWIFT WIDE OFFSET SCALE"
                )

                print(
                    "  storage bytes: "
                    + String(
                        wideRow.cellStorage.count
                    )
                )

                print(
                    "  offset bytes: "
                    + String(
                        wideRow.cellOffsets.count
                    )
                )

                for candidate in scaleCandidates {
                    print(
                        "  "
                        + offsetScaleDescription(
                            candidate
                        )
                    )
                }

                let validScales =
                    scaleCandidates
                        .filter(
                            \.isValid
                        )
                        .map(
                            \.scale
                        )

                try Expect.equal(
                    validScales,
                    [
                        4,
                    ],
                    "wide-offset.unique-scale"
                )

                let scaleFour =
                    scaleCandidates
                        .first {
                            $0.scale == 4
                        }

                try Expect.true(
                    scaleFour != nil,
                    "wide-offset.scale-four-present"
                )

                try Expect.equal(
                    scaleFour?.slotCount,
                    300,
                    "wide-offset.scale-four-slot-count"
                )

                try Expect.equal(
                    scaleFour?.presentCount,
                    300,
                    "wide-offset.scale-four-present-count"
                )

                try Expect.equal(
                    scaleFour?.firstScaledOffset,
                    0,
                    "wide-offset.scale-four-first-offset"
                )

                try Expect.equal(
                    scaleFour?.minimumRecordLength,
                    36,
                    "wide-offset.scale-four-minimum-record-length"
                )

                try Expect.equal(
                    scaleFour?.maximumRecordLength,
                    36,
                    "wide-offset.scale-four-maximum-record-length"
                )

                try Expect.true(
                    scaleFour?.allOffsetsInBounds
                    == true,
                    "wide-offset.scale-four-bounds"
                )

                try Expect.true(
                    scaleFour?.strictlyIncreasing
                    == true,
                    "wide-offset.scale-four-order"
                )

                try Expect.true(
                    scaleFour?.allRecordsAtLeastBNCHeader
                    == true,
                    "wide-offset.scale-four-record-lengths"
                )

                try Expect.true(
                    scaleFour?.allRecordsBeginBNCV5
                    == true,
                    "wide-offset.scale-four-bnc-v5-boundaries"
                )

                let nativeStorage =
                    try NumbersPackageReader
                        .storageProfile(
                            at: documentURL
                        )

                let nativeWideTables =
                    nativeStorage.tables.filter {
                        $0.name == "Wide"
                    }

                try Expect.equal(
                    nativeWideTables.count,
                    1,
                    "wide-offset.native-wide-table-count"
                )

                let decodedRows =
                    nativeWideTables[0]
                        .tiles
                        .flatMap(
                            \.rows
                        )
                        .filter {
                            $0.cellCount > 0
                        }

                try Expect.equal(
                    decodedRows.count,
                    1,
                    "wide-offset.native-populated-row-count"
                )

                let decodedRow =
                    decodedRows[0]

                try Expect.equal(
                    decodedRow.layout,
                    .bncV5,
                    "wide-offset.native-storage-layout"
                )

                try Expect.equal(
                    decodedRow.offsetSlotCount,
                    300,
                    "wide-offset.native-slot-count"
                )

                try Expect.equal(
                    decodedRow.cellOffsetsByteCount,
                    600,
                    "wide-offset.native-offset-byte-count"
                )

                try Expect.equal(
                    decodedRow.cellStorageByteCount,
                    10_800,
                    "wide-offset.native-storage-byte-count"
                )

                try Expect.equal(
                    decodedRow.records.count,
                    300,
                    "wide-offset.native-record-count"
                )

                try Expect.equal(
                    decodedRow.records.map(
                        \.columnIndex
                    ),
                    Array(
                        0..<300
                    ),
                    "wide-offset.native-column-index-range"
                )

                let nativeValues =
                    decodedRow.records.compactMap(
                        \.primitiveValue
                    )

                try Expect.equal(
                    nativeValues.count,
                    300,
                    "wide-offset.native-primitive-count"
                )

                try Expect.equal(
                    nativeValues[0],
                    .number(
                        Decimal(
                            1
                        )
                    ),
                    "wide-offset.native-first-value"
                )

                try Expect.equal(
                    nativeValues[299],
                    .number(
                        Decimal(
                            300
                        )
                    ),
                    "wide-offset.native-last-value"
                )

                let canonicalSnapshot =
                    try AppleNumbers.snapshot(
                        at: documentURL
                    )

                try Expect.equal(
                    canonicalSnapshot.sheets.count,
                    1,
                    "wide-offset.canonical-sheet-count"
                )

                let canonicalWideTables =
                    canonicalSnapshot
                        .sheets[0]
                        .tables
                        .filter {
                            $0.name == "Wide"
                        }

                try Expect.equal(
                    canonicalWideTables.count,
                    1,
                    "wide-offset.canonical-wide-table-count"
                )

                let canonicalWideTable =
                    canonicalWideTables[0]

                try Expect.equal(
                    canonicalWideTable.columnCount,
                    300,
                    "wide-offset.canonical-column-count"
                )

                try Expect.true(
                    !canonicalWideTable.rows.isEmpty,
                    "wide-offset.canonical-row-present"
                )

                let canonicalValues =
                    canonicalWideTable
                        .rows[0]
                        .cells
                        .map(
                            \.value
                        )

                try Expect.equal(
                    canonicalValues.count,
                    300,
                    "wide-offset.canonical-value-count"
                )

                try Expect.equal(
                    nativeValues,
                    canonicalValues,
                    "wide-offset.native-canonical-row-parity"
                )

                print(
                    "SWIFT WIDE OFFSET DECODE"
                )

                print(
                    "  offset entry width: 2 bytes"
                )

                print(
                    "  offset unit width: 4 bytes"
                )

                print(
                    "  decoded slots: "
                    + String(
                        decodedRow.offsetSlotCount
                    )
                )

                print(
                    "  decoded records: "
                    + String(
                        decodedRow.records.count
                    )
                )

                print(
                    "  primitive values: "
                    + String(
                        nativeValues.count
                    )
                )

                print(
                    "  column range: 0..."
                    + String(
                        decodedRow.records.last?
                            .columnIndex
                        ?? -1
                    )
                )

                print(
                    "  canonical parity: true"
                )
            }
        }
    }
}

private struct OffsetScaleAnalysis {
    let scale: Int
    let slotCount: Int
    let presentCount: Int
    let firstScaledOffset: Int?
    let lastScaledOffset: Int?
    let minimumRecordLength: Int?
    let maximumRecordLength: Int?
    let allOffsetsInBounds: Bool
    let strictlyIncreasing: Bool
    let allRecordsAtLeastBNCHeader: Bool
    let allRecordsBeginBNCV5: Bool

    var isValid: Bool {
        presentCount > 0
        && allOffsetsInBounds
        && strictlyIncreasing
        && allRecordsAtLeastBNCHeader
        && allRecordsBeginBNCV5
    }
}

private func offsetScaleAnalysis(
    bytes: [UInt8],
    storage: [UInt8],
    scale: Int
) -> OffsetScaleAnalysis {
    guard
        scale > 0,
        bytes.count.isMultiple(
            of: 2
        )
    else {
        return OffsetScaleAnalysis(
            scale:
                scale,
            slotCount:
                0,
            presentCount:
                0,
            firstScaledOffset:
                nil,
            lastScaledOffset:
                nil,
            minimumRecordLength:
                nil,
            maximumRecordLength:
                nil,
            allOffsetsInBounds:
                false,
            strictlyIncreasing:
                false,
            allRecordsAtLeastBNCHeader:
                false,
            allRecordsBeginBNCV5:
                false
        )
    }

    let slotCount =
        bytes.count / 2

    var scaledOffsets:
        [Int] = []

    scaledOffsets.reserveCapacity(
        slotCount
    )

    for slotIndex in 0..<slotCount {
        let byteIndex =
            slotIndex * 2

        let raw =
            UInt16(
                bytes[
                    byteIndex
                ]
            )
            | (
                UInt16(
                    bytes[
                        byteIndex + 1
                    ]
                )
                << 8
            )

        if raw == UInt16.max {
            continue
        }

        scaledOffsets.append(
            Int(
                raw
            )
            * scale
        )
    }

    let allOffsetsInBounds =
        scaledOffsets.allSatisfy {
            $0 >= 0
            && $0 < storage.count
        }

    let strictlyIncreasing =
        zip(
            scaledOffsets,
            scaledOffsets.dropFirst()
        )
        .allSatisfy {
            $0.0 < $0.1
        }

    var recordLengths:
        [Int] = []

    var allRecordsAtLeastBNCHeader =
        allOffsetsInBounds

    var allRecordsBeginBNCV5 =
        allOffsetsInBounds

    if allOffsetsInBounds {
        for index in scaledOffsets.indices {
            let start =
                scaledOffsets[
                    index
                ]

            let end =
                index + 1 < scaledOffsets.count
                ? scaledOffsets[
                    index + 1
                ]
                : storage.count

            guard
                end > start,
                end <= storage.count
            else {
                allRecordsAtLeastBNCHeader =
                    false

                allRecordsBeginBNCV5 =
                    false

                continue
            }

            let length =
                end - start

            recordLengths.append(
                length
            )

            if length < 12 {
                allRecordsAtLeastBNCHeader =
                    false
            }

            if storage[start] != 5 {
                allRecordsBeginBNCV5 =
                    false
            }
        }
    }

    return OffsetScaleAnalysis(
        scale:
            scale,
        slotCount:
            slotCount,
        presentCount:
            scaledOffsets.count,
        firstScaledOffset:
            scaledOffsets.first,
        lastScaledOffset:
            scaledOffsets.last,
        minimumRecordLength:
            recordLengths.min(),
        maximumRecordLength:
            recordLengths.max(),
        allOffsetsInBounds:
            allOffsetsInBounds,
        strictlyIncreasing:
            strictlyIncreasing,
        allRecordsAtLeastBNCHeader:
            allRecordsAtLeastBNCHeader,
        allRecordsBeginBNCV5:
            allRecordsBeginBNCV5
    )
}

private func offsetScaleDescription(
    _ candidate: OffsetScaleAnalysis
) -> String {
    var description =
        "scale="
        + String(
            candidate.scale
        )

    description +=
        " slots="
        + String(
            candidate.slotCount
        )

    description +=
        " present="
        + String(
            candidate.presentCount
        )

    description +=
        " first="
        + optionalIntDescription(
            candidate.firstScaledOffset
        )

    description +=
        " last="
        + optionalIntDescription(
            candidate.lastScaledOffset
        )

    description +=
        " minRecord="
        + optionalIntDescription(
            candidate.minimumRecordLength
        )

    description +=
        " maxRecord="
        + optionalIntDescription(
            candidate.maximumRecordLength
        )

    description +=
        " inBounds="
        + String(
            candidate.allOffsetsInBounds
        )

    description +=
        " increasing="
        + String(
            candidate.strictlyIncreasing
        )

    description +=
        " headerLength="
        + String(
            candidate.allRecordsAtLeastBNCHeader
        )

    description +=
        " bncV5="
        + String(
            candidate.allRecordsBeginBNCV5
        )

    description +=
        " valid="
        + String(
            candidate.isValid
        )

    return description
}

private func optionalIntDescription(
    _ value: Int?
) -> String {
    guard let value else {
        return "nil"
    }

    return String(
        value
    )
}

private struct OffsetCandidateAnalysis {
    let width: Int
    let slotCount: Int
    let presentCount: Int
    let allPresentOffsetsInBounds: Bool
    let uniquePresentOffsets: Bool
}

private func offsetCandidateAnalysis(
    bytes: [UInt8],
    width: Int,
    storageByteCount: Int
) -> OffsetCandidateAnalysis? {
    guard
        width == 2
        || width == 4,
        bytes.count.isMultiple(
            of: width
        )
    else {
        return nil
    }

    let slotCount =
        bytes.count / width

    var offsets:
        [UInt64] = []

    offsets.reserveCapacity(
        slotCount
    )

    for slotIndex in 0..<slotCount {
        let byteIndex =
            slotIndex * width

        let raw:
            UInt64

        if width == 2 {
            raw =
                UInt64(
                    bytes[
                        byteIndex
                    ]
                )
                | (
                    UInt64(
                        bytes[
                            byteIndex + 1
                        ]
                    )
                    << 8
                )

            if raw == UInt64(
                UInt16.max
            ) {
                continue
            }
        } else {
            raw =
                UInt64(
                    bytes[
                        byteIndex
                    ]
                )
                | (
                    UInt64(
                        bytes[
                            byteIndex + 1
                        ]
                    )
                    << 8
                )
                | (
                    UInt64(
                        bytes[
                            byteIndex + 2
                        ]
                    )
                    << 16
                )
                | (
                    UInt64(
                        bytes[
                            byteIndex + 3
                        ]
                    )
                    << 24
                )

            if raw == UInt64(
                UInt32.max
            ) {
                continue
            }
        }

        offsets.append(
            raw
        )
    }

    let allPresentOffsetsInBounds =
        offsets.allSatisfy {
            $0 < UInt64(
                storageByteCount
            )
        }

    let uniquePresentOffsets =
        Set(
            offsets
        )
        .count
        == offsets.count

    return OffsetCandidateAnalysis(
        width:
            width,
        slotCount:
            slotCount,
        presentCount:
            offsets.count,
        allPresentOffsetsInBounds:
            allPresentOffsetsInBounds,
        uniquePresentOffsets:
            uniquePresentOffsets
    )
}

private func offsetCandidateDescription(
    _ candidate: OffsetCandidateAnalysis?
) -> String {
    guard let candidate else {
        return "invalid-byte-count"
    }

    var description =
        String(
            candidate.width
        )
        + "B/slot slots="
        + String(
            candidate.slotCount
        )

    description +=
        " present="
        + String(
            candidate.presentCount
        )

    description +=
        " inBounds="
        + String(
            candidate.allPresentOffsetsInBounds
        )

    description +=
        " unique="
        + String(
            candidate.uniquePresentOffsets
        )

    return description
}

private func wideFlagDescription(
    _ value: Bool?
) -> String {
    switch value {
    case .some(
        true
    ):
        return "true"

    case .some(
        false
    ):
        return "false"

    case nil:
        return "absent"
    }
}

private func createNumbersWideOffsetFixture(
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
                set its name to "Wide Offsets"

                set existingTables to every table

                repeat with existingTable in existingTables
                    delete existingTable
                end repeat

                set wideTable to make new table with properties ¬
                    {name:"Wide", row count:2, column count:300, ¬
                        header row count:0, header column count:0, ¬
                        footer row count:0}

                tell wideTable
                    repeat with columnIndex from 1 to 300
                        set value of cell columnIndex of row 1 to columnIndex
                    end repeat
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
                "wide-offset.applescript"
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
                ?? "<non-UTF8 wide-offset stderr>"
        )
    }
}
