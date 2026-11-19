@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeTileStorageFlow:
        TestFlow
    {
        TestFlow(
            "numbers-native-tile-storage",
            tags: [
                "numbers",
                "native",
                "iwa",
                "table",
                "tile",
                "storage",
                "bnc-v5",
            ]
        ) {
            Step(
                "Swift resolves TableModel DataStore tile references and modern BNC cell-storage buffers"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix: "TileStorageFlow"
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
                            "Tile-Probe.numbers"
                        )

                try createNumbersFixture(
                    at: documentURL
                )

                let profile =
                    try NumbersPackageReader.storageProfile(
                        at: documentURL
                    )

                try Expect.equal(
                    Set(
                        profile.tables.map(
                            \.name
                        )
                    ),
                    Set(
                        [
                            "Clients",
                            "Invoices",
                        ]
                    ),
                    "native-storage.table-membership"
                )

                guard
                    let clients =
                        profile.tables.first(
                            where: {
                                $0.name == "Clients"
                            }
                        ),
                    let invoices =
                        profile.tables.first(
                            where: {
                                $0.name == "Invoices"
                            }
                        )
                else {
                    throw AppleNumbersError
                        .invalidSnapshotTransport(
                            "native tile-storage profile is missing Clients or Invoices"
                        )
                }

                try Expect.true(
                    !clients.tiles.isEmpty,
                    "native-storage.clients.tiles"
                )

                try Expect.true(
                    !invoices.tiles.isEmpty,
                    "native-storage.invoices.tiles"
                )

                let allTiles =
                    profile.tables.flatMap(
                        \.tiles
                    )

                let allRows =
                    allTiles.flatMap(
                        \.rows
                    )

                let populatedRows =
                    allRows.filter {
                        $0.cellCount > 0
                    }

                let records =
                    populatedRows.flatMap(
                        \.records
                    )

                let declaredPopulatedCellCount =
                    populatedRows.reduce(
                        0
                    ) {
                        $0 + $1.cellCount
                    }

                try Expect.true(
                    !allRows.isEmpty,
                    "native-storage.tile-rows"
                )

                try Expect.true(
                    !populatedRows.isEmpty,
                    "native-storage.populated-tile-rows"
                )

                try Expect.true(
                    populatedRows.allSatisfy {
                        $0.cellStorageByteCount > 0
                    },
                    "native-storage.populated-rows-have-cell-bytes"
                )

                try Expect.true(
                    populatedRows.allSatisfy {
                        $0.cellOffsetsByteCount > 0
                    },
                    "native-storage.populated-rows-have-offsets"
                )

                try Expect.equal(
                    Set(
                        populatedRows.map(
                            \.layout
                        )
                    ),
                    Set(
                        [
                            NumbersCellStorageLayout.bncV5,
                        ]
                    ),
                    "native-storage.current-fixture-uses-bnc-v5"
                )

                try Expect.true(
                    allTiles.allSatisfy {
                        $0.storageVersion == 5
                    },
                    "native-storage.tile-storage-version-5"
                )

                try Expect.equal(
                    Set(
                        populatedRows.map(
                            \.offsetSlotCount
                        )
                    ),
                    Set(
                        [
                            255,
                        ]
                    ),
                    "native-storage.current-fixture-offset-slots"
                )

                try Expect.equal(
                    records.count,
                    declaredPopulatedCellCount,
                    "native-storage.record-count-matches-row-cell-counts"
                )

                try Expect.equal(
                    records.count,
                    36,
                    "native-storage.current-fixture-record-count"
                )

                try Expect.equal(
                    Set(
                        records.map(
                            \.version
                        )
                    ),
                    Set(
                        [
                            UInt8(
                                5
                            ),
                        ]
                    ),
                    "native-storage.current-fixture-cell-record-version"
                )

                try Expect.true(
                    records.allSatisfy {
                        $0.byteCount >= 12
                    },
                    "native-storage.bnc-v5-record-header-bounds"
                )

                let observedTypes =
                    Set(
                        records.map(
                            \.type
                        )
                    )

                for expectedType in [
                    UInt8(
                        2
                    ),
                    UInt8(
                        3
                    ),
                    UInt8(
                        5
                    ),
                    UInt8(
                        6
                    ),
                ] {
                    try Expect.true(
                        observedTypes.contains(
                            expectedType
                        ),
                        "native-storage.current-fixture-type-\(expectedType)"
                    )
                }

                try Expect.true(
                    records.contains {
                        $0.fieldMask
                            & UInt32(
                                0x000200
                            )
                            != 0
                    },
                    "native-storage.current-fixture-formula-field"
                )

                try Expect.true(
                    clients.stringTableReference != nil,
                    "native-storage.clients.string-table"
                )

                try Expect.true(
                    clients.styleTableReference != nil,
                    "native-storage.clients.style-table"
                )

                try Expect.true(
                    clients.formulaTableReference != nil,
                    "native-storage.clients.formula-table"
                )

                try Expect.true(
                    clients.formatTableReference != nil,
                    "native-storage.clients.format-table"
                )

                let storedCellCount =
                    allRows.reduce(
                        0
                    ) {
                        $0 + $1.cellCount
                    }

                let cellStorageBytes =
                    allRows.reduce(
                        0
                    ) {
                        $0 + $1.cellStorageByteCount
                    }

                let offsetBytes =
                    allRows.reduce(
                        0
                    ) {
                        $0 + $1.cellOffsetsByteCount
                    }

                print(
                    "SWIFT TILE STORAGE"
                )

                print(
                    "  tables: "
                    + String(
                        profile.tables.count
                    )
                )

                print(
                    "  tiles: "
                    + String(
                        allTiles.count
                    )
                )

                print(
                    "  tile rows: "
                    + String(
                        allRows.count
                    )
                )

                print(
                    "  stored cells: "
                    + String(
                        storedCellCount
                    )
                )

                print(
                    "  cell-storage bytes: "
                    + String(
                        cellStorageBytes
                    )
                )

                print(
                    "  offset bytes: "
                    + String(
                        offsetBytes
                    )
                )

                print(
                    "  storage layouts: "
                    + Set(
                        populatedRows.map(
                            \.layout.rawValue
                        )
                    )
                    .sorted()
                    .joined(
                        separator: ", "
                    )
                )

                print(
                    "  storage versions: "
                    + Set(
                        allTiles.compactMap(
                            \.storageVersion
                        )
                    )
                    .sorted()
                    .map(
                        String.init
                    )
                    .joined(
                        separator: ", "
                    )
                )


                let typeCounts =
                    Dictionary(
                        grouping:
                            records,
                        by:
                            \.type
                    )
                    .mapValues(
                        \.count
                    )

                let fieldMasks =
                    Set(
                        records.map(
                            \.fieldMask
                        )
                    )
                    .sorted()
                    .map {
                        "0x"
                        + String(
                            $0,
                            radix: 16,
                            uppercase: false
                        )
                    }
                    .joined(
                        separator: ", "
                    )

                print(
                    "SWIFT CELL RECORDS"
                )

                print(
                    "  offset slots/row: "
                    + Set(
                        populatedRows.map(
                            \.offsetSlotCount
                        )
                    )
                    .sorted()
                    .map(
                        String.init
                    )
                    .joined(
                        separator: ", "
                    )
                )

                print(
                    "  records: "
                    + String(
                        records.count
                    )
                )

                print(
                    "  versions: "
                    + Set(
                        records.map(
                            \.version
                        )
                    )
                    .sorted()
                    .map {
                        String(
                            $0
                        )
                    }
                    .joined(
                        separator: ", "
                    )
                )

                print(
                    "  types:"
                )

                for type in typeCounts.keys.sorted() {
                    print(
                        "    "
                        + String(
                            type
                        )
                        + ": "
                        + String(
                            typeCounts[
                                type
                            ]
                            ?? 0
                        )
                    )
                }

                print(
                    "  field masks: "
                    + fieldMasks
                )
            }
        }
    }
}
