@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeFormatMatrixFlow: TestFlow {
        TestFlow(
            "numbers-native-format-matrix",
            tags: [
                "numbers",
                "native",
                "format",
                "bnc-v5",
                "integration",
            ]
        ) {
            Step(
                "Numbers scalar and control formats resolve canonically from BNC-v5 storage"
            ) {
                let directory =
                    try numbersTestFixtureDirectory(
                        prefix: "FormatMatrix"
                    )

                defer {
                    try? FileManager.default.removeItem(
                        at: directory
                    )
                }

                let documentURL =
                    directory.appendingPathComponent(
                        "Format-Matrix.numbers"
                    )

                try createNumbersFormatMatrixFixture(
                    at: documentURL
                )

                let snapshot =
                    try AppleNumbers.snapshot(
                        at: documentURL
                    )

                try characterizeNumbersFormattedStorage(
                    snapshot:
                        snapshot,
                    documentURL:
                        documentURL
                )

                try characterizeNumbersFormattedRenderingOracle(
                    snapshot:
                        snapshot
                )

                let storage =
                    try NumbersPackageReader.storageProfile(
                        at: documentURL
                    )

                try characterizeNumbersFormatMatrix(
                    snapshot: snapshot,
                    storage: storage
                )

                let formats =
                    try NumbersPackageReader.formatProfile(
                        at: documentURL
                    )

                try characterizeNumbersFormatMatrixTable(
                    formats
                )

                let dataStores =
                    try NumbersPackageReader.dataStoreProfile(
                        at: documentURL
                    )

                try characterizeNumbersFormatDataStore(
                    dataStores
                )

                let modernDataLists =
                    try NumbersPackageReader.modernDataListProfile(
                        at: documentURL
                    )

                try characterizeNumbersModernDataLists(
                    snapshot: snapshot,
                    storage: storage,
                    profile: modernDataLists
                )

                let nativeSnapshot =
                    try NumbersPackageReader.nativeSnapshot(
                        at:
                            documentURL
                    )

                let nativeSnapshotParity =
                    nativeSnapshot
                    == snapshot

                print(
                    "SWIFT FORMAT MATRIX NATIVE SNAPSHOT"
                )

                print(
                    "  full parity including formatted: "
                    + String(
                        nativeSnapshotParity
                    )
                )

                try Expect.equal(
                    nativeSnapshot,
                    snapshot,
                    "format-matrix.native-snapshot.full-parity"
                )
            }
        }
    }
}

private let formatMatrixCases:
    [(String, NumbersCellFormat)] = [
        ("automatic", .automatic),
        ("checkbox", .checkbox),
        ("currency", .currency),
        ("date and time", .dateAndTime),
        ("fraction", .fraction),
        ("number", .automatic),
        ("percent", .percent),
        ("pop up menu", .popUpMenu),
        ("scientific", .scientific),
        ("slider", .slider),
        ("stepper", .stepper),
        ("text", .automatic),
        ("duration", .duration),
        ("rating", .rating),
        ("numeral system", .numeralSystem),
    ]

private struct FormatMatrixCoordinate:
    Hashable
{
    let row: Int
    let column: Int
}

private func characterizeNumbersFormattedStorage(
    snapshot: NumbersSnapshot,
    documentURL: URL
) throws {
    guard
        snapshot.sheets.count == 1,
        let snapshotTable =
            snapshot.sheets[0]
                .tables.first(
                    where: {
                        $0.name == "Formats"
                    }
                )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "formatted-storage characterization missing Formats table"
        )
    }

    var matrixCells:
        [
            (
                label: String,
                cell: NumbersCellSnapshot
            )
        ] = []

    for (
        index,
        item
    ) in formatMatrixCases.enumerated() {
        let row =
            index + 2

        guard
            let canonicalRow =
                snapshotTable.rows.first(
                    where: {
                        $0.index == row
                    }
                ),
            let canonicalCell =
                canonicalRow.cells.first(
                    where: {
                        $0.column == 2
                    }
                )
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "formatted-storage characterization missing R\(row)C2"
            )
        }

        guard canonicalCell.formatted != nil else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "formatted-storage characterization has nil canonical display value at R\(row)C2"
            )
        }

        matrixCells.append(
            (
                label:
                    item.0,
                cell:
                    canonicalCell
            )
        )
    }

    try Expect.equal(
        matrixCells.count,
        formatMatrixCases.count,
        "formatted-storage.canonical-case-count"
    )

    let displayDifferentCells =
        matrixCells.filter {
            item in

            guard let formatted =
                item.cell.formatted
            else {
                return false
            }

            return formatted
                != primitiveStorageLexeme(
                    item.cell.value
                )
        }

    try Expect.true(
        !displayDifferentCells.isEmpty,
        "formatted-storage.has-display-different-cases"
    )

    let needles =
        displayDifferentCells.compactMap {
            $0.cell.formatted
        }

    let probe =
        try NumbersPackageReader
            .formattedStorageProbe(
                at:
                    documentURL,
                needles:
                    needles
            )

    let distinctNeedles =
        Set(
            needles
        )

    try Expect.equal(
        probe.matches.count,
        distinctNeedles.count,
        "formatted-storage.distinct-needle-count"
    )

    try Expect.true(
        probe.messageCount > 0,
        "formatted-storage.has-object-messages"
    )

    try Expect.true(
        probe.payloadByteCount > 0,
        "formatted-storage.has-object-payload"
    )

    let matchesByNeedle =
        Dictionary(
            uniqueKeysWithValues:
                probe.matches.map {
                    (
                        $0.needle,
                        $0
                    )
                }
        )

    let utf8Occurrences =
        probe.matches.reduce(
            0
        ) {
            $0
            + $1.utf8OccurrenceCount
        }

    let utf16LittleEndianOccurrences =
        probe.matches.reduce(
            0
        ) {
            $0
            + $1.utf16LittleEndianOccurrenceCount
        }

    let utf16BigEndianOccurrences =
        probe.matches.reduce(
            0
        ) {
            $0
            + $1.utf16BigEndianOccurrenceCount
        }

    let serializedNeedleCount =
        probe.matches.filter {
            $0.totalOccurrenceCount > 0
        }
        .count

    print(
        "SWIFT FORMATTED VALUE STORAGE"
    )

    print(
        "  object messages: "
        + String(
            probe.messageCount
        )
    )

    print(
        "  object payload bytes: "
        + String(
            probe.payloadByteCount
        )
    )

    print(
        "  canonical format cases: "
        + String(
            matrixCells.count
        )
    )

    print(
        "  canonical formatted values: "
        + String(
            matrixCells.filter {
                $0.cell.formatted != nil
            }
            .count
        )
    )

    print(
        "  display-different cases: "
        + String(
            displayDifferentCells.count
        )
    )

    print(
        "  distinct display needles: "
        + String(
            distinctNeedles.count
        )
    )

    print(
        "  exact UTF-8 occurrences: "
        + String(
            utf8Occurrences
        )
    )

    print(
        "  exact UTF-16LE occurrences: "
        + String(
            utf16LittleEndianOccurrences
        )
    )

    print(
        "  exact UTF-16BE occurrences: "
        + String(
            utf16BigEndianOccurrences
        )
    )

    print(
        "  exact serialized display needles: "
        + String(
            serializedNeedleCount
        )
        + "/"
        + String(
            distinctNeedles.count
        )
    )

    print(
        "  CASES"
    )

    for item in displayDifferentCells {
        guard
            let formatted =
                item.cell.formatted,
            let match =
                matchesByNeedle[
                    formatted
                ]
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "formatted-storage characterization lost a probed display string"
            )
        }

        print(
            "    "
            + item.label
            + ": kind="
            + item.cell.value.kind.rawValue
            + " format="
            + item.cell.format.rawValue
            + " utf8="
            + String(
                match.utf8OccurrenceCount
            )
            + " utf16le="
            + String(
                match.utf16LittleEndianOccurrenceCount
            )
            + " utf16be="
            + String(
                match.utf16BigEndianOccurrenceCount
            )
        )
    }

    print(
        "END SWIFT FORMATTED VALUE STORAGE"
    )
}

private func characterizeNumbersFormattedRenderingOracle(
    snapshot: NumbersSnapshot
) throws {
    guard
        snapshot.sheets.count == 1,
        let snapshotTable =
            snapshot.sheets[0]
                .tables.first(
                    where: {
                        $0.name == "Formats"
                    }
                )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "formatted rendering oracle missing Formats table"
        )
    }

    print(
        "SWIFT FORMATTED RENDERING ORACLE"
    )

    print(
        "  host locale: "
        + Locale.current.identifier
    )

    print(
        "  host time zone: "
        + TimeZone.current.identifier
    )

    print(
        "  cases: "
        + String(
            formatMatrixCases.count
        )
    )

    for (
        index,
        item
    ) in formatMatrixCases.enumerated() {
        let row =
            index + 2

        guard
            let canonicalRow =
                snapshotTable.rows.first(
                    where: {
                        $0.index == row
                    }
                ),
            let canonicalCell =
                canonicalRow.cells.first(
                    where: {
                        $0.column == 2
                    }
                ),
            let formatted =
                canonicalCell.formatted
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "formatted rendering oracle missing canonical R\(row)C2"
            )
        }

        let primitive =
            primitiveStorageLexeme(
                canonicalCell.value
            )

        print(
            "  CASE "
            + item.0
        )

        print(
            "    kind: "
            + canonicalCell.value.kind.rawValue
        )

        print(
            "    format: "
            + canonicalCell.format.rawValue
        )

        print(
            "    primitive: \""
            + escapedSyntheticDisplay(
                primitive
                ?? "<nil>"
            )
            + "\""
        )

        print(
            "    display: \""
            + escapedSyntheticDisplay(
                formatted
            )
            + "\""
        )

        print(
            "    display-scalars: "
            + unicodeScalarSignature(
                formatted
            )
        )

        print(
            "    equals-primitive: "
            + String(
                formatted
                    == primitive
            )
        )
    }

    print(
        "END SWIFT FORMATTED RENDERING ORACLE"
    )
}

private func escapedSyntheticDisplay(
    _ value: String
) -> String {
    var result =
        ""

    for scalar in value.unicodeScalars {
        switch scalar.value {
        case 0x09:
            result += "\\t"

        case 0x0A:
            result += "\\n"

        case 0x0D:
            result += "\\r"

        case 0x22:
            result += "\\\""

        case 0x5C:
            result += "\\\\"

        case 0x00A0,
             0x202F:
            result +=
                "\\u{"
                + String(
                    scalar.value,
                    radix:
                        16,
                    uppercase:
                        true
                )
                + "}"

        default:
            if
                scalar.value < 0x20
                || scalar.value == 0x7F
            {
                result +=
                    "\\u{"
                    + String(
                        scalar.value,
                        radix:
                            16,
                        uppercase:
                            true
                    )
                    + "}"
            } else {
                result +=
                    String(
                        scalar
                    )
            }
        }
    }

    return result
}

private func unicodeScalarSignature(
    _ value: String
) -> String {
    value.unicodeScalars
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
}

private func primitiveStorageLexeme(
    _ value: NumbersCellValue
) -> String? {
    switch value {
    case .empty:
        return nil

    case .text(
        let value
    ):
        return value

    case .number(
        let value
    ):
        return NSDecimalNumber(
            decimal:
                value
        )
        .stringValue

    case .boolean(
        let value
    ):
        return value
            ? "true"
            : "false"

    case .date(
        let value
    ):
        return ISO8601DateFormatter()
            .string(
                from:
                    value
            )
    }
}

private func characterizeNumbersFormatMatrix(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile
) throws {
    guard
        snapshot.sheets.count == 1,
        let snapshotTable =
            snapshot.sheets[0]
                .tables.first(
                    where: {
                        $0.name == "Formats"
                    }
                )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "format matrix canonical table missing"
        )
    }

    guard let storageTable =
        storage.tables.first(
            where: {
                $0.name == "Formats"
            }
        )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "format matrix native storage table missing"
        )
    }

    try Expect.equal(
        snapshotTable.rowCount,
        16,
        "native-format-matrix.row-count"
    )

    try Expect.equal(
        snapshotTable.columnCount,
        2,
        "native-format-matrix.column-count"
    )

    try Expect.equal(
        snapshotTable.headerRowCount,
        1,
        "native-format-matrix.header-row-count"
    )

    var records:
        [
            FormatMatrixCoordinate:
                NumbersNativeTableStorageProfile.CellRecord
        ] = [:]

    for tile in storageTable.tiles {
        for nativeRow in tile.rows {
            let row =
                nativeRow.tileRowIndex
                + 1

            for record in nativeRow.records {
                let coordinate =
                    FormatMatrixCoordinate(
                        row: row,
                        column:
                            record.columnIndex
                            + 1
                    )

                guard records[coordinate] == nil else {
                    throw AppleNumbersError.invalidSnapshotTransport(
                        "format matrix duplicate native record R\(row)C\(record.columnIndex + 1)"
                    )
                }

                records[coordinate] =
                    record
            }
        }
    }

    var actualFormats:
        [NumbersCellFormat] = []

    var nativeRecordCount =
        0

    print(
        "SWIFT FORMAT MATRIX"
    )

    print(
        "  canonical cases: \(formatMatrixCases.count)"
    )

    for (
        index,
        item
    ) in formatMatrixCases.enumerated() {
        let row =
            index + 2

        guard let canonicalRow =
            snapshotTable.rows.first(
                where: {
                    $0.index == row
                }
            )
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "format matrix canonical row \(row) missing"
            )
        }

        guard let canonicalCell =
            canonicalRow.cells.first(
                where: {
                    $0.column == 2
                }
            )
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "format matrix canonical cell R\(row)C2 missing"
            )
        }

        actualFormats.append(
            canonicalCell.format
        )

        let record =
            records[
                FormatMatrixCoordinate(
                    row: row,
                    column: 2
                )
            ]

        if record != nil {
            nativeRecordCount +=
                1
        }

        print(
            "  "
            + item.0
            + ": canonical="
            + canonicalCell.format.rawValue
            + " value="
            + canonicalCell.value.kind.rawValue
            + " nativeType="
            + optionalDescription(
                record?.type
            )
            + " family="
            + (
                record?.formatFamily?.rawValue
                ?? "nil"
            )
            + " raw="
            + optionalDescription(
                record?.formatKey
            )
            + " suggested="
            + optionalDescription(
                record?.suggestedFormatKind
            )
            + " control="
            + optionalDescription(
                record?.controlCellSpecKey
            )
            + " mask="
            + (
                record.map {
                    String(
                        format: "0x%X",
                        $0.fieldMask
                    )
                }
                ?? "nil"
            )
        )
    }

    try Expect.equal(
        actualFormats,
        formatMatrixCases.map(
            \.1
        ),
        "native-format-matrix.canonical-format-order"
    )

    print(
        "  native records for formatted cells: \(nativeRecordCount)/\(formatMatrixCases.count)"
    )
}

private func characterizeNumbersFormatMatrixTable(
    _ formats: NumbersNativeFormatProfile
) throws {
    guard let table =
        formats.tables.first(
            where: {
                $0.name == "Formats"
            }
        )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "format matrix FORMAT TableDataList missing"
        )
    }

    print(
        "SWIFT FORMAT MATRIX TABLE"
    )

    print(
        "  reference: \(table.formatTableReference)"
    )

    print(
        "  nextListID: "
        + optionalDescription(
            table.nextListID
        )
    )

    print(
        "  fields: "
        + table.fieldSignatures.joined(
            separator: ","
        )
    )

    print(
        "  explicit entries: \(table.entries.count)"
    )

    for entry in table.entries {
        print(
            "    key="
            + String(
                entry.key
            )
            + " type="
            + optionalDescription(
                entry.formatType
            )
            + " fields="
            + entry.fieldSignatures.joined(
                separator: ","
            )
        )
    }
}

private func characterizeNumbersFormatDataStore(
    _ profile: NumbersNativeDataStoreProfile
) throws {
    guard let table =
        profile.tables.first(
            where: {
                $0.name == "Formats"
            }
        )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "format matrix DataStore profile missing Formats table"
        )
    }

    try Expect.true(
        !table.fields.isEmpty,
        "native-format-matrix.datastore-has-fields"
    )

    try Expect.true(
        table.fields.contains {
            $0.number == 11
            && $0.wireType == 2
        },
        "native-format-matrix.datastore-retains-field11"
    )

    print(
        "SWIFT FORMAT DATASTORE GRAPH"
    )

    print(
        "  table model: \(table.tableModelIdentifier)"
    )

    print(
        "  fields: "
        + table.fieldSignatures.joined(
            separator: ","
        )
    )

    for field in table.fields {
        var line =
            "    field="

        line +=
            String(
                field.number
            )

        line +=
            "/"

        line +=
            String(
                field.wireType
            )

        if let value =
            field.varint
        {
            line +=
                " value="

            line +=
                String(
                    value
                )
        }

        if field.wireType == 2 {
            line +=
                " bytes="

            line +=
                String(
                    field.byteCount
                )

            let nestedDescription:
                String

            if let nested =
                field.nestedFieldSignatures
            {
                nestedDescription =
                    nested.joined(
                        separator: ","
                    )
            } else {
                nestedDescription =
                    "unparsed"
            }

            line +=
                " nested="

            line +=
                nestedDescription

            let referenceDescription =
                optionalDescription(
                    field.referenceIdentifierCandidate
                )

            line +=
                " referenceCandidate="

            line +=
                referenceDescription

            let objectsDescription:
                String

            if field.referencedObjects.isEmpty {
                objectsDescription =
                    "-"
            } else {
                var objectDescriptions:
                    [String] = []

                objectDescriptions.reserveCapacity(
                    field.referencedObjects.count
                )

                for object in field.referencedObjects {
                    let objectFieldsDescription:
                        String

                    if let signatures =
                        object.fieldSignatures
                    {
                        objectFieldsDescription =
                            signatures.joined(
                                separator: ","
                            )
                    } else {
                        objectFieldsDescription =
                            "unparsed"
                    }

                    var objectDescription =
                        "id="

                    objectDescription +=
                        String(
                            object.identifier
                        )

                    objectDescription +=
                        "/type="

                    objectDescription +=
                        String(
                            object.type
                        )

                    objectDescription +=
                        "/bytes="

                    objectDescription +=
                        String(
                            object.payloadByteCount
                        )

                    objectDescription +=
                        "/fields="

                    objectDescription +=
                        objectFieldsDescription

                    objectDescriptions.append(
                        objectDescription
                    )
                }

                objectsDescription =
                    objectDescriptions.joined(
                        separator: ";"
                    )
            }

            line +=
                " objects="

            line +=
                objectsDescription
        }

        print(
            line
        )
    }

}

private func characterizeNumbersModernDataLists(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile,
    profile: NumbersNativeModernDataListProfile
) throws {
    guard
        snapshot.sheets.count == 1,
        let snapshotTable =
            snapshot.sheets[0]
                .tables.first(
                    where: {
                        $0.name == "Formats"
                    }
                )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "modern DataList characterization missing canonical Formats table"
        )
    }

    guard let storageTable =
        storage.tables.first(
            where: {
                $0.name == "Formats"
            }
        )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "modern DataList characterization missing native Formats table"
        )
    }

    guard let profileTable =
        profile.tables.first(
            where: {
                $0.name == "Formats"
            }
        )
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "modern DataList profile missing Formats table"
        )
    }

    guard let controlTable =
        profileTable.controlCellSpecTable
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "Formats table missing DataStore field 21 control-cell-spec table"
        )
    }

    guard let formatTable =
        profileTable.formatTable
    else {
        throw AppleNumbersError.invalidSnapshotTransport(
            "Formats table missing DataStore field 22 modern format table"
        )
    }

    try Expect.equal(
        controlTable.dataStoreFieldNumber,
        21,
        "native-modern-datalists.control-field"
    )

    try Expect.equal(
        controlTable.listType,
        12,
        "native-modern-datalists.control-list-type"
    )

    try Expect.equal(
        formatTable.dataStoreFieldNumber,
        22,
        "native-modern-datalists.format-field"
    )

    try Expect.equal(
        formatTable.listType,
        2,
        "native-modern-datalists.format-list-type"
    )

    var records:
        [
            FormatMatrixCoordinate:
                NumbersNativeTableStorageProfile.CellRecord
        ] = [:]

    for tile in storageTable.tiles {
        for nativeRow in tile.rows {
            let row =
                nativeRow.tileRowIndex
                + 1

            for record in nativeRow.records {
                let coordinate =
                    FormatMatrixCoordinate(
                        row: row,
                        column:
                            record.columnIndex
                            + 1
                    )

                guard records[coordinate] == nil else {
                    throw AppleNumbersError.invalidSnapshotTransport(
                        "modern DataList characterization duplicate native record R\(row)C\(record.columnIndex + 1)"
                    )
                }

                records[coordinate] =
                    record
            }
        }
    }

    var formatEntries:
        [
            UInt32:
                NumbersNativeModernDataListProfile.Entry
        ] = [:]

    for entry in formatTable.entries {
        guard formatEntries[entry.key] == nil else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "modern format table contains duplicate key \(entry.key)"
            )
        }

        formatEntries[entry.key] =
            entry
    }

    var controlEntries:
        [
            UInt32:
                NumbersNativeModernDataListProfile.Entry
        ] = [:]

    for entry in controlTable.entries {
        guard controlEntries[entry.key] == nil else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "control-cell-spec table contains duplicate key \(entry.key)"
            )
        }

        controlEntries[entry.key] =
            entry
    }

    var formatReferenceCount =
        0

    var formatDirectMatchCount =
        0

    var formatDirectMissCount =
        0

    var distinctFormatKeys:
        Set<UInt32> = []

    var controlReferenceCount =
        0

    var controlDirectMatchCount =
        0

    var controlDirectMissCount =
        0

    var distinctControlKeys:
        Set<UInt32> = []

    var resolvedFormatCount =
        0

    var resolvedControlFormatCount =
        0

    var resolvedScalarFormatCount =
        0

    print(
        "SWIFT MODERN DATA LISTS"
    )

    printModernDataListSummary(
        label: "control",
        list: controlTable
    )

    printModernDataListSummary(
        label: "format",
        list: formatTable
    )

    print(
        "  FORMAT ENTRIES"
    )

    for entry in formatTable.entries {
        printModernFormatEntry(
            entry
        )
    }

    print(
        "  CONTROL ENTRIES"
    )

    for entry in controlTable.entries {
        printModernControlEntry(
            entry
        )
    }

    print(
        "  MATRIX CORRELATION"
    )

    for (
        index,
        item
    ) in formatMatrixCases.enumerated() {
        let row =
            index + 2

        guard let canonicalRow =
            snapshotTable.rows.first(
                where: {
                    $0.index == row
                }
            ),
            let canonicalCell =
                canonicalRow.cells.first(
                    where: {
                        $0.column == 2
                    }
                )
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "modern DataList characterization canonical cell R\(row)C2 missing"
            )
        }

        guard let record =
            records[
                FormatMatrixCoordinate(
                    row: row,
                    column: 2
                )
            ]
        else {
            throw AppleNumbersError.invalidSnapshotTransport(
                "modern DataList characterization native cell R\(row)C2 missing"
            )
        }

        let formatEntry:
            NumbersNativeModernDataListProfile.Entry?

        if let formatKey =
            record.formatKey
        {
            formatReferenceCount +=
                1

            distinctFormatKeys.insert(
                formatKey
            )

            formatEntry =
                formatEntries[
                    formatKey
                ]

            if formatEntry == nil {
                formatDirectMissCount +=
                    1
            } else {
                formatDirectMatchCount +=
                    1
            }
        } else {
            formatEntry =
                nil
        }

        let controlEntry:
            NumbersNativeModernDataListProfile.Entry?

        if let controlKey =
            record.controlCellSpecKey
        {
            controlReferenceCount +=
                1

            distinctControlKeys.insert(
                controlKey
            )

            controlEntry =
                controlEntries[
                    controlKey
                ]

            if controlEntry == nil {
                controlDirectMissCount +=
                    1
            } else {
                controlDirectMatchCount +=
                    1
            }
        } else {
            controlEntry =
                nil
        }

        let resolvedFormat =
            try NumbersPackageReader.resolvedCellFormat(
                for: record,
                in: profileTable
            )

        try Expect.equal(
            resolvedFormat,
            canonicalCell.format,
            "native-cell-format-resolver.\(item.0)"
        )

        resolvedFormatCount +=
            1

        if record.controlCellSpecKey == nil {
            resolvedScalarFormatCount +=
                1
        } else {
            resolvedControlFormatCount +=
                1
        }

        printModernMatrixCorrelation(
            label: item.0,
            canonicalFormat: canonicalCell.format,
            record: record,
            formatEntry: formatEntry,
            controlEntry: controlEntry
        )
    }

    print(
        "SWIFT NATIVE FORMAT RESOLUTION"
    )

    print(
        "  exact canonical matches: \(resolvedFormatCount)/\(formatMatrixCases.count)"
    )

    print(
        "  control-backed matches: \(resolvedControlFormatCount)"
    )

    print(
        "  format-only matches: \(resolvedScalarFormatCount)"
    )

    try Expect.equal(
        resolvedFormatCount,
        formatMatrixCases.count,
        "native-cell-format-resolver.exact-match-count"
    )

    try Expect.equal(
        resolvedControlFormatCount,
        5,
        "native-cell-format-resolver.control-backed-count"
    )

    try Expect.equal(
        resolvedScalarFormatCount,
        10,
        "native-cell-format-resolver.format-only-count"
    )

    print(
        "  format references: \(formatReferenceCount)"
    )

    print(
        "  distinct format keys: \(distinctFormatKeys.count)"
    )

    print(
        "  format direct matches: \(formatDirectMatchCount)"
    )

    print(
        "  format direct misses: \(formatDirectMissCount)"
    )

    print(
        "  control references: \(controlReferenceCount)"
    )

    print(
        "  distinct control keys: \(distinctControlKeys.count)"
    )

    print(
        "  control direct matches: \(controlDirectMatchCount)"
    )

    print(
        "  control direct misses: \(controlDirectMissCount)"
    )

    try Expect.equal(
        formatReferenceCount,
        formatMatrixCases.count,
        "native-modern-datalists.all-matrix-cells-have-format-key"
    )

    try Expect.equal(
        formatDirectMissCount,
        0,
        "native-modern-datalists.format-keys-resolve-directly"
    )

    try Expect.equal(
        formatDirectMatchCount,
        formatReferenceCount,
        "native-modern-datalists.all-format-keys-resolved"
    )

    try Expect.equal(
        controlReferenceCount,
        5,
        "native-modern-datalists.control-reference-count"
    )

    try Expect.equal(
        distinctControlKeys.count,
        5,
        "native-modern-datalists.control-key-count"
    )

    try Expect.equal(
        controlDirectMissCount,
        0,
        "native-modern-datalists.control-keys-resolve-directly"
    )

    try Expect.equal(
        controlDirectMatchCount,
        controlReferenceCount,
        "native-modern-datalists.all-control-keys-resolved"
    )

    try Expect.true(
        formatTable.entries.allSatisfy {
            $0.formatArchive != nil
        },
        "native-modern-datalists.format-entries-have-format-archives"
    )

    try Expect.true(
        controlTable.entries.allSatisfy {
            $0.cellSpecArchive != nil
        },
        "native-modern-datalists.control-entries-have-cell-spec-archives"
    )
}

private func printModernDataListSummary(
    label: String,
    list: NumbersNativeModernDataListProfile.DataList
) {
    var line =
        "  "

    line +=
        label

    line +=
        " field: "

    line +=
        String(
            list.dataStoreFieldNumber
        )

    line +=
        " reference="

    line +=
        String(
            list.referenceIdentifier
        )

    line +=
        " listType="

    line +=
        String(
            list.listType
        )

    line +=
        " nextListID="

    line +=
        optionalDescription(
            list.nextListID
        )

    line +=
        " newForBNC="

    line +=
        optionalDescription(
            list.isNewForBNC
        )

    line +=
        " entries="

    line +=
        String(
            list.entries.count
        )

    line +=
        " segments="

    line +=
        String(
            list.segmentReferences.count
        )

    line +=
        " fields="

    line +=
        list.fieldSignatures.joined(
            separator: ","
        )

    print(
        line
    )
}

private func printModernFormatEntry(
    _ entry: NumbersNativeModernDataListProfile.Entry
) {
    let archive =
        entry.formatArchive

    var line =
        "    key="

    line +=
        String(
            entry.key
        )

    line +=
        " refcount="

    line +=
        optionalDescription(
            entry.refcount
        )

    line +=
        " entryFields="

    line +=
        entry.fieldSignatures.joined(
            separator: ","
        )

    line +=
        " formatType="

    line +=
        optionalDescription(
            archive?.formatType
        )

    line +=
        " decimalPlaces="

    line +=
        optionalDescription(
            archive?.decimalPlaces
        )

    line +=
        " currency="

    line +=
        optionalDescription(
            archive?.currencyCode
        )

    line +=
        " durationStyle="

    line +=
        optionalDescription(
            archive?.durationStyle
        )

    line +=
        " base="

    line +=
        optionalDescription(
            archive?.base
        )

    line +=
        " basePlaces="

    line +=
        optionalDescription(
            archive?.basePlaces
        )

    line +=
        " fractionAccuracy="

    line +=
        optionalDescription(
            archive?.fractionAccuracy
        )

    line +=
        " dateTime="

    line +=
        optionalDescription(
            archive?.dateTimeFormat
        )

    line +=
        " scale="

    line +=
        optionalDescription(
            archive?.scaleFactor
        )

    line +=
        " autoDuration="

    line +=
        optionalDescription(
            archive?.useAutomaticDurationUnits
        )

    line +=
        " formatFields="

    if let signatures =
        archive?.fieldSignatures
    {
        line +=
            signatures.joined(
                separator: ","
            )
    } else {
        line +=
            "nil"
    }

    print(
        line
    )
}

private func printModernControlEntry(
    _ entry: NumbersNativeModernDataListProfile.Entry
) {
    let archive =
        entry.cellSpecArchive

    var line =
        "    key="

    line +=
        String(
            entry.key
        )

    line +=
        " refcount="

    line +=
        optionalDescription(
            entry.refcount
        )

    line +=
        " entryFields="

    line +=
        entry.fieldSignatures.joined(
            separator: ","
        )

    line +=
        " interaction="

    line +=
        optionalDescription(
            archive?.interactionType
        )

    line +=
        " min="

    line +=
        optionalDescription(
            archive?.rangeControlMinimum
        )

    line +=
        " max="

    line +=
        optionalDescription(
            archive?.rangeControlMaximum
        )

    line +=
        " increment="

    line +=
        optionalDescription(
            archive?.rangeControlIncrement
        )

    line +=
        " popup="

    line +=
        optionalDescription(
            archive?.chooserPopupReference
        )

    line +=
        " startsFirst="

    line +=
        optionalDescription(
            archive?.chooserStartsWithFirst
        )

    line +=
        " specFields="

    if let signatures =
        archive?.fieldSignatures
    {
        line +=
            signatures.joined(
                separator: ","
            )
    } else {
        line +=
            "nil"
    }

    print(
        line
    )
}

private func printModernMatrixCorrelation(
    label: String,
    canonicalFormat: NumbersCellFormat,
    record: NumbersNativeTableStorageProfile.CellRecord,
    formatEntry: NumbersNativeModernDataListProfile.Entry?,
    controlEntry: NumbersNativeModernDataListProfile.Entry?
) {
    var line =
        "    "

    line +=
        label

    line +=
        ": canonical="

    line +=
        canonicalFormat.rawValue

    line +=
        " family="

    if let family =
        record.formatFamily
    {
        line +=
            family.rawValue
    } else {
        line +=
            "nil"
    }

    line +=
        " formatKey="

    line +=
        optionalDescription(
            record.formatKey
        )

    line +=
        " formatEntry="

    line +=
        optionalDescription(
            formatEntry?.key
        )

    line +=
        " formatType="

    line +=
        optionalDescription(
            formatEntry?
                .formatArchive?
                .formatType
        )

    line +=
        " formatFields="

    if let signatures =
        formatEntry?
            .formatArchive?
            .fieldSignatures
    {
        line +=
            signatures.joined(
                separator: ","
            )
    } else {
        line +=
            "nil"
    }

    line +=
        " controlKey="

    line +=
        optionalDescription(
            record.controlCellSpecKey
        )

    line +=
        " controlEntry="

    line +=
        optionalDescription(
            controlEntry?.key
        )

    line +=
        " interaction="

    line +=
        optionalDescription(
            controlEntry?
                .cellSpecArchive?
                .interactionType
        )

    line +=
        " controlFields="

    if let signatures =
        controlEntry?
            .cellSpecArchive?
            .fieldSignatures
    {
        line +=
            signatures.joined(
                separator: ","
            )
    } else {
        line +=
            "nil"
    }

    print(
        line
    )
}

private func optionalDescription<T>(
    _ value: T?
) -> String {
    value.map {
        String(
            describing: $0
        )
    }
    ?? "nil"
}

private func createNumbersFormatMatrixFixture(
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
            tell active sheet
                set its name to "Format Probe"

                set existingTables to every table

                repeat with existingTable in existingTables
                    delete existingTable
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
                "format-matrix.applescript"
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
                ?? "<non-UTF8 format-matrix stderr>"
        )
    }
}
