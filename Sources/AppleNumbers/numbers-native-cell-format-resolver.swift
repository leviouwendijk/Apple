import Foundation

@_spi(Testing)
public extension NumbersPackageReader {
    static func resolvedCellFormat(
        for record: NumbersNativeTableStorageProfile.CellRecord,
        in table: NumbersNativeModernDataListProfile.Table
    ) throws -> NumbersCellFormat {
        try NumbersNativeCellFormatResolver.resolve(
            record,
            in: table
        )
    }
}

enum NumbersNativeCellFormatResolver {
    static func resolve(
        _ record: NumbersNativeTableStorageProfile.CellRecord,
        in table: NumbersNativeModernDataListProfile.Table
    ) throws -> NumbersCellFormat {
        guard record.version == 5 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "native canonical format resolution requires BNC-v5, found cell version \(record.version)"
                )
        }

        guard
            let formatTable =
                table.formatTable,
            formatTable.dataStoreFieldNumber == 22,
            formatTable.listType == 2
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) is missing its modern BNC FORMAT DataList"
                )
        }

        guard let formatKey =
            record.formatKey
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) BNC-v5 cell has no format key"
                )
        }

        let formatEntry =
            try uniqueEntry(
                key:
                    formatKey,
                in:
                    formatTable,
                context:
                    "table \(table.name) modern FORMAT"
            )

        guard
            let formatArchive =
                formatEntry.formatArchive,
            let formatType =
                formatArchive.formatType
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) modern FORMAT key \(formatKey) has no FormatStructArchive format type"
                )
        }

        if let controlKey =
            record.controlCellSpecKey
        {
            guard
                let controlTable =
                    table.controlCellSpecTable,
                controlTable.dataStoreFieldNumber == 21,
                controlTable.listType == 12
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) cell references control key \(controlKey) but has no modern CONTROL_CELL_SPEC DataList"
                    )
            }

            let controlEntry =
                try uniqueEntry(
                    key:
                        controlKey,
                    in:
                        controlTable,
                    context:
                        "table \(table.name) modern CONTROL_CELL_SPEC"
                )

            guard
                let cellSpec =
                    controlEntry.cellSpecArchive,
                let interactionType =
                    cellSpec.interactionType
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) CONTROL_CELL_SPEC key \(controlKey) has no interaction type"
                    )
            }

            return try controlFormat(
                interactionType,
                tableName:
                    table.name,
                controlKey:
                    controlKey,
                baseFormatType:
                    formatType
            )
        }

        return try scalarFormat(
            formatType,
            tableName:
                table.name,
            formatKey:
                formatKey
        )
    }

    private static func controlFormat(
        _ interactionType: UInt64,
        tableName: String,
        controlKey: UInt32,
        baseFormatType: UInt64
    ) throws -> NumbersCellFormat {
        switch interactionType {
        case 4:
            return .stepper

        case 5:
            return .slider

        case 6:
            return .rating

        case 7:
            return .popUpMenu

        case 8:
            return .checkbox

        default:
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) CONTROL_CELL_SPEC key \(controlKey) has unsupported interaction type \(interactionType) with base format type \(baseFormatType)"
                )
        }
    }

    private static func scalarFormat(
        _ formatType: UInt64,
        tableName: String,
        formatKey: UInt32
    ) throws -> NumbersCellFormat {
        switch formatType {
        case 256, 260:
            return .automatic

        case 257:
            return .currency

        case 258:
            return .percent

        case 259:
            return .scientific

        case 261:
            return .dateAndTime

        case 262:
            return .fraction

        case 268:
            return .duration

        case 269:
            return .numeralSystem

        default:
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) modern FORMAT key \(formatKey) has unsupported canonical format type \(formatType)"
                )
        }
    }

    private static func uniqueEntry(
        key: UInt32,
        in list: NumbersNativeModernDataListProfile.DataList,
        context: String
    ) throws -> NumbersNativeModernDataListProfile.Entry {
        let matches =
            list.entries.filter {
                $0.key == key
            }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context) key \(key) resolved to \(matches.count) entries"
                )
        }

        return matches[0]
    }
}
