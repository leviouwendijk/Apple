@_spi(Testing) import AppleNumbers
import TestFlows

func characterizeNativeFormatKeySpace(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile,
    formats: NumbersNativeFormatProfile
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

    let formatTables =
        Dictionary(
            uniqueKeysWithValues:
                formats.tables.map {
                    (
                        $0.name,
                        $0
                    )
                }
        )

    var referenceCount =
        0

    var directMatchCount =
        0

    var directMissCount =
        0

    var usage:
        [FormatUseKey: Int] = [:]

    var canonicalFormats:
        [FormatUseKey: Set<String>] = [:]

    var formulaCounts:
        [FormatUseKey: Int] = [:]

    for storageTable in storage.tables {
        guard let snapshotTable =
            snapshotTables[
                storageTable.name
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "format key-space table \(storageTable.name) has no canonical snapshot table"
                )
        }

        guard let formatTable =
            formatTables[
                storageTable.name
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "format key-space table \(storageTable.name) has no decoded FORMAT TableDataList"
                )
        }

        guard let storageReference =
            storageTable.formatTableReference
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "storage table \(storageTable.name) has no format-table reference"
                )
        }

        try Expect.equal(
            formatTable.formatTableReference,
            storageReference,
            "native-format-key-space.\(storageTable.name).reference"
        )

        let entriesByKey =
            Dictionary(
                uniqueKeysWithValues:
                    formatTable.entries.map {
                        (
                            $0.key,
                            $0
                        )
                    }
            )

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
                            "format key-space row \(storageTable.name) R\(rowIndex) missing from canonical snapshot"
                        )
                }

                for record in storageRow.records {
                    guard
                        let family =
                            record.formatFamily,
                        let rawID =
                            record.formatKey
                    else {
                        throw AppleNumbersError
                            .invalidSnapshotTransport(
                                "format key-space cell \(storageTable.name) R\(rowIndex)C\(record.columnIndex + 1) is missing its BNC format family/id"
                            )
                    }

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
                                "format key-space cell \(storageTable.name) R\(rowIndex)C\(columnIndex) missing from canonical snapshot"
                            )
                    }

                    let signature =
                        FormatUseKey(
                            tableName:
                                storageTable.name,
                            family:
                                family,
                            rawID:
                                rawID
                        )

                    referenceCount +=
                        1

                    usage[
                        signature,
                        default: 0
                    ] += 1

                    canonicalFormats[
                        signature,
                        default: []
                    ]
                    .insert(
                        canonicalCell
                            .format
                            .rawValue
                    )

                    if record.formulaKey
                        != nil
                    {
                        formulaCounts[
                            signature,
                            default: 0
                        ] += 1
                    }

                    if entriesByKey[rawID]
                        != nil
                    {
                        directMatchCount +=
                            1
                    } else {
                        directMissCount +=
                            1
                    }
                }
            }
        }
    }

    try Expect.equal(
        referenceCount,
        36,
        "native-format-key-space.reference-count"
    )

    try Expect.equal(
        directMatchCount
            + directMissCount,
        referenceCount,
        "native-format-key-space.direct-accounting"
    )

    try Expect.true(
        directMissCount > 0,
        "native-format-key-space.current-fixture-has-direct-key-misses"
    )

    try Expect.true(
        formats.tables.allSatisfy {
            $0.nextListID
                != nil
        },
        "native-format-key-space.format-tables-have-next-list-id"
    )

    print(
        "SWIFT FORMAT KEY SPACE"
    )

    print(
        "  cell format references: "
        + String(
            referenceCount
        )
    )

    print(
        "  direct ListEntry.key matches: "
        + String(
            directMatchCount
        )
    )

    print(
        "  direct ListEntry.key misses: "
        + String(
            directMissCount
        )
    )

    print(
        "  table format lists:"
    )

    for table in formats.tables {
        let keys =
            table.entries
                .map {
                    String(
                        $0.key
                    )
                }
                .joined(
                    separator: ","
                )

        let observedRawIDs =
            usage.keys
                .filter {
                    $0.tableName
                        == table.name
                }
                .map(
                    \.rawID
                )
                .sorted()

        let observedRawDescription =
            observedRawIDs
                .map {
                    String(
                        $0
                    )
                }
                .joined(
                    separator: ","
                )

        let allObservedBelowNext:
            Bool?

        if let nextListID =
            table.nextListID
        {
            allObservedBelowNext =
                observedRawIDs
                    .allSatisfy {
                        $0 < nextListID
                    }
        } else {
            allObservedBelowNext =
                nil
        }

        print(
            "    "
            + table.name
            + ": reference="
            + String(
                table.formatTableReference
            )
            + " nextListID="
            + optionalDescription(
                table.nextListID
            )
            + " fields="
            + table.fieldSignatures
                .joined(
                    separator: ","
                )
            + " entries="
            + String(
                table.entries.count
            )
            + " keys="
            + (
                keys.isEmpty
                ? "-"
                : keys
            )
            + " observedRaw="
            + (
                observedRawDescription.isEmpty
                ? "-"
                : observedRawDescription
            )
            + " observedBelowNext="
            + optionalDescription(
                allObservedBelowNext
            )
        )
    }

    print(
        "  decoded format entries:"
    )

    for table in formats.tables {
        for entry in table.entries {
            print(
                "    "
                + table.name
                + " "
                + describe(
                    entry
                )
            )
        }
    }

    print(
        "  BNC format-reference candidates:"
    )

    let orderedUses =
        usage.keys.sorted {
            if $0.tableName
                != $1.tableName
            {
                return $0.tableName
                    < $1.tableName
            }

            if $0.family.rawValue
                != $1.family.rawValue
            {
                return $0.family.rawValue
                    < $1.family.rawValue
            }

            return $0.rawID
                < $1.rawID
        }

    for signature in orderedUses {
        guard let table =
            formatTables[
                signature.tableName
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "format key-space diagnostics lost table \(signature.tableName)"
                )
        }

        let direct =
            table.entries.first {
                $0.key
                    == signature.rawID
            }

        let rawIndex =
            Int(
                signature.rawID
            )

        let oneBased:
            NumbersNativeFormatProfile.Entry?

        if rawIndex > 0,
           rawIndex <= table.entries.count
        {
            oneBased =
                table.entries[
                    rawIndex - 1
                ]
        } else {
            oneBased = nil
        }

        let zeroBased:
            NumbersNativeFormatProfile.Entry?

        if rawIndex >= 0,
           rawIndex < table.entries.count
        {
            zeroBased =
                table.entries[
                    rawIndex
                ]
        } else {
            zeroBased = nil
        }

        let typeMatches =
            table.entries.filter {
                $0.formatType
                    == UInt64(
                        signature.rawID
                    )
            }

        let canonicals =
            canonicalFormats[
                signature
            ]
            ?? []

        print(
            "    "
            + signature.tableName
            + " family="
            + signature.family.rawValue
            + " raw="
            + String(
                signature.rawID
            )
            + " usage="
            + String(
                usage[
                    signature
                ]
                ?? 0
            )
            + " canonical="
            + canonicals
                .sorted()
                .joined(
                    separator: ","
                )
            + " formulas="
            + String(
                formulaCounts[
                    signature
                ]
                ?? 0
            )
        )

        print(
            "      direct-key="
            + compactDescription(
                direct
            )
        )

        print(
            "      one-based-ordinal="
            + compactDescription(
                oneBased
            )
        )

        print(
            "      zero-based-ordinal="
            + compactDescription(
                zeroBased
            )
        )

        print(
            "      format-type-matches="
            + (
                typeMatches.isEmpty
                ? "nil"
                : typeMatches
                    .map(
                        compactDescription
                    )
                    .joined(
                        separator: ";"
                    )
            )
        )
    }
}

private struct FormatUseKey:
    Hashable
{
    let tableName: String
    let family: NumbersNativeCellFormatFamily
    let rawID: UInt32
}

private func describe(
    _ entry: NumbersNativeFormatProfile.Entry
) -> String {
    "key="
    + String(
        entry.key
    )
    + " refcount="
    + optionalDescription(
        entry.refcount
    )
    + " type="
    + optionalDescription(
        entry.formatType
    )
    + " fields="
    + entry.fieldSignatures
        .joined(
            separator: ","
        )
    + " decimalPlaces="
    + optionalDescription(
        entry.decimalPlaces
    )
    + " currency="
    + (
        entry.currencyCode
        ?? "nil"
    )
    + " thousands="
    + optionalDescription(
        entry.showThousandsSeparator
    )
    + " accounting="
    + optionalDescription(
        entry.useAccountingStyle
    )
    + " dateFormat="
    + quotedDescription(
        entry.dateTimeFormat
    )
}

private func compactDescription(
    _ entry: NumbersNativeFormatProfile.Entry?
) -> String {
    guard let entry else {
        return "nil"
    }

    return "key="
        + String(
            entry.key
        )
        + "/type="
        + optionalDescription(
            entry.formatType
        )
        + "/fields="
        + entry.fieldSignatures
            .joined(
                separator: ","
            )
}

private func optionalDescription<T>(
    _ value: T?
) -> String {
    value.map {
        String(
            describing:
                $0
        )
    }
    ?? "nil"
}

private func quotedDescription(
    _ value: String?
) -> String {
    guard let value else {
        return "nil"
    }

    return "\""
        + value
        + "\""
}
