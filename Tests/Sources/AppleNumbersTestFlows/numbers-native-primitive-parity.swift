@_spi(Testing) import AppleNumbers
import TestFlows

func proveNativePrimitiveParity(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile
) throws {
    guard snapshot.sheets.count == 1 else {
        throw AppleNumbersError
            .invalidSnapshotTransport(
                "native primitive parity expected one synthetic sheet, found \(snapshot.sheets.count)"
            )
    }

    let snapshotTables =
        Dictionary(
            uniqueKeysWithValues:
                snapshot.sheets[0]
                    .tables
                    .map {
                        (
                            $0.name,
                            $0
                        )
                    }
        )

    var decodedPrimitiveCount =
        0

    var decodedKinds:
        [NumbersCellValue.Kind: Int] = [:]

    var typesByKind:
        [NumbersCellValue.Kind: Set<UInt8>] = [:]

    var formulaRecords:
        [NumbersNativeTableStorageProfile.CellRecord] = []

    for storageTable in storage.tables {
        guard let snapshotTable =
            snapshotTables[
                storageTable.name
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native primitive storage table \(storageTable.name) has no snapshot table"
                )
        }

        for tile in storageTable.tiles {
            for storageRow in tile.rows {
                let snapshotRowIndex =
                    storageRow.tileRowIndex
                    + 1

                guard let snapshotRow =
                    snapshotTable.rows.first(
                        where: {
                            $0.index
                                == snapshotRowIndex
                        }
                    )
                else {
                    throw AppleNumbersError
                        .invalidSnapshotTransport(
                            "native primitive row \(snapshotRowIndex) is missing from \(storageTable.name)"
                        )
                }

                for record in storageRow.records {
                    guard let primitive =
                        record.primitiveValue
                    else {
                        throw AppleNumbersError
                            .invalidSnapshotTransport(
                                "native primitive decoder did not decode \(storageTable.name) R\(snapshotRowIndex)C\(record.columnIndex + 1), type=\(record.type), mask=0x\(String(record.fieldMask, radix: 16))"
                            )
                    }

                    let snapshotColumnIndex =
                        record.columnIndex
                        + 1

                    guard let snapshotCell =
                        snapshotRow.cells.first(
                            where: {
                                $0.column
                                    == snapshotColumnIndex
                            }
                        )
                    else {
                        throw AppleNumbersError
                            .invalidSnapshotTransport(
                                "native primitive column \(snapshotColumnIndex) is missing from \(storageTable.name) row \(snapshotRowIndex)"
                            )
                    }

                    try Expect.equal(
                        primitive,
                        snapshotCell.value,
                        "native-primitive.\(storageTable.name).R\(snapshotRowIndex)C\(snapshotColumnIndex)"
                    )

                    try Expect.equal(
                        record.unparsedTrailingByteCount,
                        0,
                        "native-primitive.\(storageTable.name).R\(snapshotRowIndex)C\(snapshotColumnIndex).trailing-bytes"
                    )

                    decodedPrimitiveCount +=
                        1

                    decodedKinds[
                        primitive.kind,
                        default: 0
                    ] +=
                        1

                    typesByKind[
                        primitive.kind,
                        default: []
                    ]
                    .insert(
                        record.type
                    )

                    if record.formulaKey != nil {
                        formulaRecords.append(
                            record
                        )
                    }
                }
            }
        }
    }

    try Expect.equal(
        decodedPrimitiveCount,
        36,
        "native-primitive.current-fixture-decoded-count"
    )

    try Expect.equal(
        decodedKinds[.text],
        15,
        "native-primitive.text-count"
    )

    try Expect.equal(
        decodedKinds[.number],
        15,
        "native-primitive.number-count"
    )

    try Expect.equal(
        decodedKinds[.boolean],
        3,
        "native-primitive.boolean-count"
    )

    try Expect.equal(
        decodedKinds[.date],
        3,
        "native-primitive.date-count"
    )

    try Expect.equal(
        typesByKind[.text],
        Set(
            [
                UInt8(
                    3
                ),
            ]
        ),
        "native-primitive.text-types"
    )

    try Expect.equal(
        typesByKind[.boolean],
        Set(
            [
                UInt8(
                    6
                ),
            ]
        ),
        "native-primitive.boolean-types"
    )

    try Expect.equal(
        typesByKind[.date],
        Set(
            [
                UInt8(
                    5
                ),
            ]
        ),
        "native-primitive.date-types"
    )

    try Expect.equal(
        typesByKind[.number],
        Set(
            [
                UInt8(
                    2
                ),
                UInt8(
                    10
                ),
            ]
        ),
        "native-primitive.number-types"
    )

    try Expect.equal(
        formulaRecords.count,
        3,
        "native-primitive.formula-record-count"
    )

    try Expect.equal(
        Set(
            formulaRecords.map(
                \.type
            )
        ),
        Set(
            [
                UInt8(
                    10
                ),
            ]
        ),
        "native-primitive.formula-record-types"
    )

    try Expect.true(
        formulaRecords.allSatisfy {
            $0.fieldMask
                & UInt32(
                    0x000200
                )
                != 0
        },
        "native-primitive.formula-record-mask"
    )

    print(
        "SWIFT PRIMITIVE CELLS"
    )

    print(
        "  decoded: "
        + String(
            decodedPrimitiveCount
        )
    )

    for kind in [
        NumbersCellValue.Kind.text,
        .number,
        .boolean,
        .date,
    ] {
        let types =
            typesByKind[
                kind
            ]
            ?? []

        print(
            "  \(kind.rawValue): "
            + String(
                decodedKinds[
                    kind
                ]
                ?? 0
            )
            + " cells; BNC types="
            + types
                .sorted()
                .map {
                    String(
                        $0
                    )
                }
                .joined(
                    separator: ","
                )
        )
    }

    print(
        "  formula references: "
        + String(
            formulaRecords.count
        )
    )
}
