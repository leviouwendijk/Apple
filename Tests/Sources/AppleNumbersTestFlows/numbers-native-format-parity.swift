@_spi(Testing) import AppleNumbers
import TestFlows

func characterizeNativeFormatReferences(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile
) throws {
    let snapshotTables =
        Dictionary(
            uniqueKeysWithValues:
                snapshot.sheets
                    .flatMap(
                        \.tables
                    )
                    .map {
                        (
                            $0.name,
                            $0
                        )
                    }
        )

    var cellCount =
        0

    var canonicalCounts:
        [String: Int] = [:]

    var familyCounts:
        [String: Int] = [:]

    var suggestedKindCounts:
        [UInt32: Int] = [:]

    var formatKeyCounts:
        [String: Int] = [:]

    var correlationCounts:
        [String: Int] = [:]

    var automaticCorrelationCounts:
        [String: Int] = [:]

    var missingFamilyCount =
        0

    var missingFormatKeyCount =
        0

    var missingSuggestedKindCount =
        0

    var controlSpecCount =
        0

    var sawAutomaticTextBoundary =
        false

    for storageTable in storage.tables {
        guard let snapshotTable =
            snapshotTables[
                storageTable.name
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native format table \(storageTable.name) has no canonical snapshot table"
                )
        }

        for tile in storageTable.tiles {
            for storageRow in tile.rows {
                let rowIndex =
                    storageRow.tileRowIndex
                    + 1

                guard let snapshotRow =
                    snapshotTable.rows.first(
                        where: {
                            $0.index
                                == rowIndex
                        }
                    )
                else {
                    throw AppleNumbersError
                        .invalidSnapshotTransport(
                            "native format row \(rowIndex) missing from \(storageTable.name)"
                        )
                }

                for record in storageRow.records {
                    let columnIndex =
                        record.columnIndex
                        + 1

                    guard let canonicalCell =
                        snapshotRow.cells.first(
                            where: {
                                $0.column
                                    == columnIndex
                            }
                        )
                    else {
                        throw AppleNumbersError
                            .invalidSnapshotTransport(
                                "native format cell \(storageTable.name) R\(rowIndex)C\(columnIndex) missing from canonical snapshot"
                            )
                    }

                    cellCount +=
                        1

                    let canonical =
                        canonicalCell
                            .format
                            .rawValue

                    canonicalCounts[
                        canonical,
                        default: 0
                    ] += 1

                    let family:
                        String

                    if let value =
                        record.formatFamily
                    {
                        family =
                            value.rawValue

                        familyCounts[
                            family,
                            default: 0
                        ] += 1
                    } else {
                        family =
                            "nil"

                        missingFamilyCount +=
                            1
                    }

                    let formatKey:
                        String

                    if let value =
                        record.formatKey
                    {
                        formatKey =
                            String(
                                value
                            )

                        let keySignature =
                            family
                            + ":"
                            + formatKey

                        formatKeyCounts[
                            keySignature,
                            default: 0
                        ] += 1
                    } else {
                        formatKey =
                            "nil"

                        missingFormatKeyCount +=
                            1
                    }

                    let suggested:
                        String

                    if let value =
                        record.suggestedFormatKind
                    {
                        suggested =
                            String(
                                value
                            )

                        suggestedKindCounts[
                            value,
                            default: 0
                        ] += 1
                    } else {
                        suggested =
                            "nil"

                        missingSuggestedKindCount +=
                            1
                    }

                    if record.controlCellSpecKey
                        != nil
                    {
                        controlSpecCount +=
                            1
                    }

                    let signature =
                        "canonical="
                        + canonical
                        + " family="
                        + family
                        + " key="
                        + formatKey
                        + " suggested="
                        + suggested

                    correlationCounts[
                        signature,
                        default: 0
                    ] += 1

                    if canonical
                        == NumbersCellFormat
                            .automatic
                            .rawValue
                    {
                        let automaticSignature =
                            "family="
                            + family
                            + " key="
                            + formatKey
                            + " suggested="
                            + suggested

                        automaticCorrelationCounts[
                            automaticSignature,
                            default: 0
                        ] += 1
                    }

                    if storageTable.name
                        == "Clients",
                       rowIndex == 1,
                       columnIndex == 1
                    {
                        try Expect.equal(
                            canonicalCell.format,
                            .automatic,
                            "native-format.boundary.clients-r1c1-canonical"
                        )

                        try Expect.equal(
                            record.formatFamily,
                            .text,
                            "native-format.boundary.clients-r1c1-family"
                        )

                        try Expect.true(
                            record.formatKey
                                != nil,
                            "native-format.boundary.clients-r1c1-key"
                        )

                        try Expect.true(
                            record.suggestedFormatKind
                                != nil,
                            "native-format.boundary.clients-r1c1-suggested-kind"
                        )

                        sawAutomaticTextBoundary =
                            true
                    }
                }
            }
        }
    }

    try Expect.equal(
        cellCount,
        36,
        "native-format.current-fixture-cell-count"
    )

    try Expect.true(
        sawAutomaticTextBoundary,
        "native-format.automatic-vs-text-family-boundary"
    )

    try Expect.true(
        (
            canonicalCounts[
                NumbersCellFormat
                    .automatic
                    .rawValue
            ]
            ?? 0
        ) > 0,
        "native-format.fixture-has-automatic-format"
    )

    print(
        "SWIFT FORMAT CORRELATION"
    )

    print(
        "  cells: "
        + String(
            cellCount
        )
    )

    print(
        "  missing native family: "
        + String(
            missingFamilyCount
        )
    )

    print(
        "  missing native format key: "
        + String(
            missingFormatKeyCount
        )
    )

    print(
        "  missing suggested kind: "
        + String(
            missingSuggestedKindCount
        )
    )

    print(
        "  control-cell specs: "
        + String(
            controlSpecCount
        )
    )

    print(
        "  canonical formats:"
    )

    for key in canonicalCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + key
            + ": "
            + String(
                canonicalCounts[
                    key
                ]
                ?? 0
            )
        )
    }

    print(
        "  native families:"
    )

    for key in familyCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + key
            + ": "
            + String(
                familyCounts[
                    key
                ]
                ?? 0
            )
        )
    }

    print(
        "  native family/key usage:"
    )

    for key in formatKeyCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + key
            + ": "
            + String(
                formatKeyCounts[
                    key
                ]
                ?? 0
            )
        )
    }

    print(
        "  suggested format kinds:"
    )

    for key in suggestedKindCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + String(
                key
            )
            + ": "
            + String(
                suggestedKindCounts[
                    key
                ]
                ?? 0
            )
        )
    }

    print(
        "  automatic correlations:"
    )

    for key in automaticCorrelationCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + key
            + ": "
            + String(
                automaticCorrelationCounts[
                    key
                ]
                ?? 0
            )
        )
    }

    print(
        "  canonical/native correlations:"
    )

    for key in correlationCounts
        .keys
        .sorted()
    {
        print(
            "    "
            + key
            + ": "
            + String(
                correlationCounts[
                    key
                ]
                ?? 0
            )
        )
    }
}
