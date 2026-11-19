import Foundation

@_spi(Testing)
public enum NumbersCellStorageLayout:
    String,
    Hashable,
    Sendable
{
    case legacy
    case bncV5 = "bnc-v5"
}

@_spi(Testing)
public enum NumbersNativeCellFormatFamily:
    String,
    Hashable,
    Sendable
{
    case number
    case currency
    case date
    case duration
    case text
    case boolean
}

@_spi(Testing)
public struct NumbersNativeTableStorageProfile:
    Equatable,
    Sendable
{
    public let tables: [Table]

    public init(
        tables: [Table]
    ) {
        self.tables = tables
    }

    public struct Table:
        Equatable,
        Sendable
    {
        public let tableModelIdentifier: UInt64
        public let name: String
        public let tiles: [Tile]

        public let stringTableReference: UInt64?
        public let styleTableReference: UInt64?
        public let formulaTableReference: UInt64?
        public let formatTableReference: UInt64?

        public init(
            tableModelIdentifier: UInt64,
            name: String,
            tiles: [Tile],
            stringTableReference: UInt64?,
            styleTableReference: UInt64?,
            formulaTableReference: UInt64?,
            formatTableReference: UInt64?
        ) {
            self.tableModelIdentifier = tableModelIdentifier
            self.name = name
            self.tiles = tiles
            self.stringTableReference = stringTableReference
            self.styleTableReference = styleTableReference
            self.formulaTableReference = formulaTableReference
            self.formatTableReference = formatTableReference
        }
    }

    public struct Tile:
        Equatable,
        Sendable
    {
        public let tileID: UInt64
        public let objectIdentifier: UInt64

        public let maxColumn: Int
        public let maxRow: Int
        public let cellCount: Int
        public let rowCount: Int

        public let storageVersion: Int?

        public let rows: [Row]

        public init(
            tileID: UInt64,
            objectIdentifier: UInt64,
            maxColumn: Int,
            maxRow: Int,
            cellCount: Int,
            rowCount: Int,
            storageVersion: Int?,
            rows: [Row]
        ) {
            self.tileID = tileID
            self.objectIdentifier = objectIdentifier
            self.maxColumn = maxColumn
            self.maxRow = maxRow
            self.cellCount = cellCount
            self.rowCount = rowCount
            self.storageVersion = storageVersion
            self.rows = rows
        }
    }

    public struct CellRecord:
        Equatable,
        Sendable
    {
        public let columnIndex: Int
        public let offset: Int
        public let byteCount: Int

        public let version: UInt8
        public let type: UInt8
        public let fieldMask: UInt32

        public let primitiveValue: NumbersCellValue?
        public let formulaKey: UInt32?

        public let suggestedFormatKind: UInt32?
        public let formatFamily: NumbersNativeCellFormatFamily?
        public let formatKey: UInt32?
        public let controlCellSpecKey: UInt32?

        public let unparsedTrailingByteCount: Int

        public init(
            columnIndex: Int,
            offset: Int,
            byteCount: Int,
            version: UInt8,
            type: UInt8,
            fieldMask: UInt32,
            primitiveValue: NumbersCellValue?,
            formulaKey: UInt32?,
            suggestedFormatKind: UInt32?,
            formatFamily: NumbersNativeCellFormatFamily?,
            formatKey: UInt32?,
            controlCellSpecKey: UInt32?,
            unparsedTrailingByteCount: Int
        ) {
            self.columnIndex = columnIndex
            self.offset = offset
            self.byteCount = byteCount
            self.version = version
            self.type = type
            self.fieldMask = fieldMask
            self.primitiveValue = primitiveValue
            self.formulaKey = formulaKey
            self.suggestedFormatKind = suggestedFormatKind
            self.formatFamily = formatFamily
            self.formatKey = formatKey
            self.controlCellSpecKey = controlCellSpecKey
            self.unparsedTrailingByteCount = unparsedTrailingByteCount
        }
    }

    public struct Row:
        Equatable,
        Sendable
    {
        public let tileRowIndex: Int
        public let cellCount: Int

        public let storageVersion: Int?
        public let layout: NumbersCellStorageLayout

        public let cellStorageByteCount: Int
        public let cellOffsetsByteCount: Int

        public let offsetSlotCount: Int
        public let records: [CellRecord]

        public init(
            tileRowIndex: Int,
            cellCount: Int,
            storageVersion: Int?,
            layout: NumbersCellStorageLayout,
            cellStorageByteCount: Int,
            cellOffsetsByteCount: Int,
            offsetSlotCount: Int,
            records: [CellRecord]
        ) {
            self.tileRowIndex = tileRowIndex
            self.cellCount = cellCount
            self.storageVersion = storageVersion
            self.layout = layout
            self.cellStorageByteCount = cellStorageByteCount
            self.cellOffsetsByteCount = cellOffsetsByteCount
            self.offsetSlotCount = offsetSlotCount
            self.records = records
        }
    }
}

@_spi(Testing)
public struct NumbersNativeWideOffsetProfile:
    Equatable,
    Sendable
{
    public let tableStorages: [TableStorage]
    public let tiles: [Tile]

    public init(
        tableStorages: [TableStorage],
        tiles: [Tile]
    ) {
        self.tableStorages = tableStorages
        self.tiles = tiles
    }

    public struct TableStorage:
        Equatable,
        Sendable
    {
        public let tableModelIdentifier: UInt64
        public let tableName: String
        public let tileSize: Int?
        public let shouldUseWideRows: Bool?

        public init(
            tableModelIdentifier: UInt64,
            tableName: String,
            tileSize: Int?,
            shouldUseWideRows: Bool?
        ) {
            self.tableModelIdentifier = tableModelIdentifier
            self.tableName = tableName
            self.tileSize = tileSize
            self.shouldUseWideRows = shouldUseWideRows
        }
    }

    public struct Tile:
        Equatable,
        Sendable
    {
        public let objectIdentifier: UInt64
        public let maxColumn: Int
        public let storageVersion: Int?
        public let shouldUseWideRows: Bool?
        public let rows: [Row]

        public init(
            objectIdentifier: UInt64,
            maxColumn: Int,
            storageVersion: Int?,
            shouldUseWideRows: Bool?,
            rows: [Row]
        ) {
            self.objectIdentifier = objectIdentifier
            self.maxColumn = maxColumn
            self.storageVersion = storageVersion
            self.shouldUseWideRows = shouldUseWideRows
            self.rows = rows
        }
    }

    public struct Row:
        Equatable,
        Sendable
    {
        public let tileRowIndex: Int
        public let cellCount: Int
        public let storageVersion: Int?
        public let hasWideOffsets: Bool?
        public let cellStorageByteCount: Int
        public let cellStorage: [UInt8]
        public let cellOffsets: [UInt8]

        public var cellOffsetsByteCount: Int {
            cellOffsets.count
        }

        public init(
            tileRowIndex: Int,
            cellCount: Int,
            storageVersion: Int?,
            hasWideOffsets: Bool?,
            cellStorageByteCount: Int,
            cellStorage: [UInt8],
            cellOffsets: [UInt8]
        ) {
            self.tileRowIndex = tileRowIndex
            self.cellCount = cellCount
            self.storageVersion = storageVersion
            self.hasWideOffsets = hasWideOffsets
            self.cellStorageByteCount = cellStorageByteCount
            self.cellStorage = cellStorage
            self.cellOffsets = cellOffsets
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func storageProfile(
        at documentURL: URL
    ) throws -> NumbersNativeTableStorageProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersTileStorageDecoder.decode(
            messages
        )
    }

    static func wideOffsetProfile(
        at documentURL: URL
    ) throws -> NumbersNativeWideOffsetProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersTileStorageDecoder
            .decodeWideOffsetProfile(
                messages
            )
    }
}

enum NumbersTileStorageDecoder {
    static let tableModelType:
        UInt32 = 6001

    static let tileType:
        UInt32 = 6002

    static let tableDataListType:
        UInt32 = 6005

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeTableStorageProfile {
        let store =
            NumbersObjectStore(
                messages
            )

        return try decode(
            messages,
            store: store
        )
    }

    static func decode(
        _ messages: [NumbersObjectMessage],
        store: NumbersObjectStore
    ) throws -> NumbersNativeTableStorageProfile {
        let tableModels =
            messages.filter {
                $0.type == tableModelType
            }

        let tables =
            try tableModels.map {
                try decodeTable(
                    $0,
                    store: store
                )
            }

        return NumbersNativeTableStorageProfile(
            tables: tables
        )
    }

    static func decodeWideOffsetProfile(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeWideOffsetProfile {
        let tableStorages =
            try messages
                .filter {
                    $0.type == tableModelType
                }
                .map {
                    message in

                    let fields =
                        try NumbersWire.decode(
                            message.payload,
                            context:
                                "TST.TableModelArchive wide-offset profile"
                        )

                    let tableName =
                        try requiredString(
                            fields,
                            number: 8,
                            context:
                                "TST.TableModelArchive.table_name"
                        )

                    guard
                        let dataStore =
                            fields.first(
                                where: {
                                    $0.number == 4
                                    && $0.wireType == 2
                                }
                            )
                    else {
                        throw NumbersObjectGraphError
                            .invalidObjectGraph(
                                "TST.TableModelArchive \(tableName) missing data_store"
                            )
                    }

                    let dataStoreFields =
                        try NumbersWire.decode(
                            dataStore.bytes,
                            context:
                                "TST.DataStore wide-offset profile"
                        )

                    guard
                        let tileStorage =
                            dataStoreFields.first(
                                where: {
                                    $0.number == 3
                                    && $0.wireType == 2
                                }
                            )
                    else {
                        throw NumbersObjectGraphError
                            .invalidObjectGraph(
                                "TST.DataStore for \(tableName) missing TileStorage"
                            )
                    }

                    let tileStorageFields =
                        try NumbersWire.decode(
                            tileStorage.bytes,
                            context:
                                "TST.TileStorage wide-offset profile"
                        )

                    return NumbersNativeWideOffsetProfile
                        .TableStorage(
                            tableModelIdentifier:
                                message.identifier,
                            tableName:
                                tableName,
                            tileSize:
                                try optionalInt(
                                    tileStorageFields,
                                    number: 2,
                                    context:
                                        "TST.TileStorage.tile_size"
                                ),
                            shouldUseWideRows:
                                try optionalBool(
                                    tileStorageFields,
                                    number: 3,
                                    context:
                                        "TST.TileStorage.should_use_wide_rows"
                                )
                        )
                }

        let tiles =
            try messages
                .filter {
                    $0.type == tileType
                }
                .map {
                    message in

                    let fields =
                        try NumbersWire.decode(
                            message.payload,
                            context:
                                "TST.Tile wide-offset profile"
                        )

                    let tileStorageVersion =
                        try optionalInt(
                            fields,
                            number: 6,
                            context:
                                "TST.Tile.storage_version"
                        )

                    let rows =
                        try fields
                            .filter {
                                $0.number == 5
                                && $0.wireType == 2
                            }
                            .map {
                                rowField in

                                let rowFields =
                                    try NumbersWire.decode(
                                        rowField.bytes,
                                        context:
                                            "TST.TileRowInfo wide-offset profile"
                                    )

                                let modernBuffer =
                                    bytesField(
                                        rowFields,
                                        number: 6
                                    )

                                let modernOffsets =
                                    bytesField(
                                        rowFields,
                                        number: 7
                                    )

                                let legacyBuffer =
                                    bytesField(
                                        rowFields,
                                        number: 3
                                    )

                                let legacyOffsets =
                                    bytesField(
                                        rowFields,
                                        number: 4
                                    )

                                return NumbersNativeWideOffsetProfile
                                    .Row(
                                        tileRowIndex:
                                            try requiredInt(
                                                rowFields,
                                                number: 1,
                                                context:
                                                    "TST.TileRowInfo.tile_row_index"
                                            ),
                                        cellCount:
                                            try requiredInt(
                                                rowFields,
                                                number: 2,
                                                context:
                                                    "TST.TileRowInfo.cell_count"
                                            ),
                                        storageVersion:
                                            try optionalInt(
                                                rowFields,
                                                number: 5,
                                                context:
                                                    "TST.TileRowInfo.storage_version"
                                            )
                                            ?? tileStorageVersion,
                                        hasWideOffsets:
                                            try optionalBool(
                                                rowFields,
                                                number: 8,
                                                context:
                                                    "TST.TileRowInfo.has_wide_offsets"
                                            ),
                                        cellStorageByteCount:
                                            modernBuffer?.count
                                            ?? legacyBuffer?.count
                                            ?? 0,
                                        cellStorage:
                                            modernBuffer
                                            ?? legacyBuffer
                                            ?? [],
                                        cellOffsets:
                                            modernOffsets
                                            ?? legacyOffsets
                                            ?? []
                                    )
                            }

                    return NumbersNativeWideOffsetProfile
                        .Tile(
                            objectIdentifier:
                                message.identifier,
                            maxColumn:
                                try requiredInt(
                                    fields,
                                    number: 1,
                                    context:
                                        "TST.Tile.maxColumn"
                                ),
                            storageVersion:
                                tileStorageVersion,
                            shouldUseWideRows:
                                try optionalBool(
                                    fields,
                                    number: 8,
                                    context:
                                        "TST.Tile.should_use_wide_rows"
                                ),
                            rows:
                                rows
                        )
                }

        return NumbersNativeWideOffsetProfile(
            tableStorages:
                tableStorages,
            tiles:
                tiles
        )
    }

    private static func decodeTable(
        _ message: NumbersObjectMessage,
        store: NumbersObjectStore
    ) throws -> NumbersNativeTableStorageProfile.Table {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.TableModelArchive"
            )

        let name =
            try requiredString(
                fields,
                number: 8,
                context:
                    "TST.TableModelArchive.table_name"
            )

        guard
            let dataStore =
                fields.first(
                    where: {
                        $0.number == 4
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableModelArchive \(name) missing data_store"
                )
        }

        let decodedStore =
            try decodeDataStore(
                dataStore.bytes,
                tableName: name,
                store: store
            )

        return NumbersNativeTableStorageProfile.Table(
            tableModelIdentifier: message.identifier,
            name: name,
            tiles: decodedStore.tiles,
            stringTableReference:
                decodedStore.stringTableReference,
            styleTableReference:
                decodedStore.styleTableReference,
            formulaTableReference:
                decodedStore.formulaTableReference,
            formatTableReference:
                decodedStore.formatTableReference
        )
    }

    private struct DataStore {
        let tiles:
            [NumbersNativeTableStorageProfile.Tile]

        let stringTableReference: UInt64?
        let styleTableReference: UInt64?
        let formulaTableReference: UInt64?
        let formatTableReference: UInt64?
    }

    private static func decodeDataStore(
        _ bytes: [UInt8],
        tableName: String,
        store: NumbersObjectStore
    ) throws -> DataStore {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.DataStore"
            )

        guard
            let tileStorage =
                fields.first(
                    where: {
                        $0.number == 3
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.DataStore for \(tableName) missing TileStorage"
                )
        }

        let tileLinks =
            try decodeTileStorage(
                tileStorage.bytes,
                tableName: tableName
            )

        let stringTableReference =
            try optionalReference(
                fields,
                number: 4,
                context:
                    "TST.DataStore.stringTable"
            )

        let strings =
            try stringTableReference.map {
                try decodeStringTable(
                    reference: $0,
                    tableName: tableName,
                    store: store
                )
            }
            ?? [:]

        let tiles =
            try tileLinks.map {
                link in

                let tileMessage =
                    try store.message(
                        identifier:
                            link.objectIdentifier,
                        type:
                            tileType,
                        context:
                            "TST.DataStore \(tableName) tile \(link.tileID)"
                    )

                return try decodeTile(
                    tileMessage,
                    tileID: link.tileID,
                    strings: strings
                )
            }

        return DataStore(
            tiles: tiles,
            stringTableReference:
                stringTableReference,
            styleTableReference:
                try optionalReference(
                    fields,
                    number: 5,
                    context:
                        "TST.DataStore.styleTable"
                ),
            formulaTableReference:
                try optionalReference(
                    fields,
                    number: 6,
                    context:
                        "TST.DataStore.formulaTable"
                ),
            formatTableReference:
                try optionalReference(
                    fields,
                    number: 11,
                    context:
                        "TST.DataStore.formatTable"
                )
        )
    }

    private struct TileLink {
        let tileID: UInt64
        let objectIdentifier: UInt64
    }

    private static func decodeTileStorage(
        _ bytes: [UInt8],
        tableName: String
    ) throws -> [TileLink] {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TileStorage"
            )

        return try fields
            .filter {
                $0.number == 1
                && $0.wireType == 2
            }
            .map {
                field in

                let linkFields =
                    try NumbersWire.decode(
                        field.bytes,
                        context:
                            "TST.TileStorage.Tile"
                    )

                guard
                    let tileID =
                        linkFields.first(
                            where: {
                                $0.number == 1
                                && $0.wireType == 0
                            }
                        )?
                        .varint
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "TST.TileStorage for \(tableName) contains a tile without tileid"
                        )
                }

                guard
                    let referenceField =
                        linkFields.first(
                            where: {
                                $0.number == 2
                                && $0.wireType == 2
                            }
                        )
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "TST.TileStorage tile \(tileID) missing object reference"
                        )
                }

                return TileLink(
                    tileID: tileID,
                    objectIdentifier:
                        try reference(
                            referenceField.bytes,
                            context:
                                "TST.TileStorage.Tile.tile"
                        )
                )
            }
    }

    private static func decodeTile(
        _ message: NumbersObjectMessage,
        tileID: UInt64,
        strings: [UInt32: String]
    ) throws -> NumbersNativeTableStorageProfile.Tile {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.Tile"
            )

        let maxColumn =
            try requiredInt(
                fields,
                number: 1,
                context:
                    "TST.Tile.maxColumn"
            )

        let maxRow =
            try requiredInt(
                fields,
                number: 2,
                context:
                    "TST.Tile.maxRow"
            )

        let cellCount =
            try requiredInt(
                fields,
                number: 3,
                context:
                    "TST.Tile.numCells"
            )

        let rowCount =
            try requiredInt(
                fields,
                number: 4,
                context:
                    "TST.Tile.numrows"
            )

        let storageVersion =
            try optionalInt(
                fields,
                number: 6,
                context:
                    "TST.Tile.storage_version"
            )

        let rows =
            try fields
                .filter {
                    $0.number == 5
                    && $0.wireType == 2
                }
                .map {
                    try decodeTileRow(
                        $0.bytes,
                        inheritedStorageVersion:
                            storageVersion,
                        strings: strings
                    )
                }

        return NumbersNativeTableStorageProfile.Tile(
            tileID: tileID,
            objectIdentifier:
                message.identifier,
            maxColumn: maxColumn,
            maxRow: maxRow,
            cellCount: cellCount,
            rowCount: rowCount,
            storageVersion:
                storageVersion,
            rows: rows
        )
    }

    private static func decodeTileRow(
        _ bytes: [UInt8],
        inheritedStorageVersion: Int?,
        strings: [UInt32: String]
    ) throws -> NumbersNativeTableStorageProfile.Row {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TileRowInfo"
            )

        let tileRowIndex =
            try requiredInt(
                fields,
                number: 1,
                context:
                    "TST.TileRowInfo.tileRowIndex"
            )

        let cellCount =
            try requiredInt(
                fields,
                number: 2,
                context:
                    "TST.TileRowInfo.cellCount"
            )

        let rowStorageVersion =
            try optionalInt(
                fields,
                number: 5,
                context:
                    "TST.TileRowInfo.storage_version"
            )

        let effectiveStorageVersion =
            rowStorageVersion
            ?? inheritedStorageVersion

        let hasWideOffsets =
            try optionalBool(
                fields,
                number: 8,
                context:
                    "TST.TileRowInfo.has_wide_offsets"
            )
            ?? false

        let modernBuffer =
            bytesField(
                fields,
                number: 6
            )

        let modernOffsets =
            bytesField(
                fields,
                number: 7
            )

        let legacyBuffer =
            bytesField(
                fields,
                number: 3
            )

        let legacyOffsets =
            bytesField(
                fields,
                number: 4
            )

        let layout:
            NumbersCellStorageLayout

        let storage:
            [UInt8]

        let offsets:
            [UInt8]

        if
            modernBuffer != nil
            || modernOffsets != nil
        {
            guard
                let modernBuffer,
                let modernOffsets
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "BNC-v5 TileRowInfo has only one of cell-storage buffer / offsets"
                    )
            }

            layout = .bncV5
            storage = modernBuffer
            offsets = modernOffsets
        } else {
            guard
                let legacyBuffer,
                let legacyOffsets
            else {
                if cellCount == 0 {
                    return NumbersNativeTableStorageProfile.Row(
                        tileRowIndex:
                            tileRowIndex,
                        cellCount:
                            cellCount,
                        storageVersion:
                            effectiveStorageVersion,
                        layout:
                            effectiveStorageVersion == 5
                            ? .bncV5
                            : .legacy,
                        cellStorageByteCount:
                            0,
                        cellOffsetsByteCount:
                            0,
                        offsetSlotCount:
                            0,
                        records:
                            []
                    )
                }

                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TileRowInfo with \(cellCount) cells contains no recognized cell-storage fields"
                    )
            }

            layout = .legacy
            storage = legacyBuffer
            offsets = legacyOffsets
        }

        let offsetUnitByteCount:
            Int

        switch (
            layout,
            hasWideOffsets
        ) {
        case (
            .bncV5,
            true
        ):
            offsetUnitByteCount =
                4

        case (
            .legacy,
            true
        ):
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TileRowInfo row \(tileRowIndex) uses wide-row offsets with legacy cell storage; only BNC-v5 wide-row offsets are characterized"
                )

        case (
            _,
            false
        ):
            offsetUnitByteCount =
                1
        }

        let decoded =
            try decodeCellRecords(
                storage: storage,
                offsets: offsets,
                offsetUnitByteCount:
                    offsetUnitByteCount,
                layout: layout,
                declaredCellCount:
                    cellCount,
                strings: strings,
                context:
                    "TST.TileRowInfo row \(tileRowIndex)"
            )

        return NumbersNativeTableStorageProfile.Row(
            tileRowIndex: tileRowIndex,
            cellCount: cellCount,
            storageVersion:
                effectiveStorageVersion,
            layout: layout,
            cellStorageByteCount:
                storage.count,
            cellOffsetsByteCount:
                offsets.count,
            offsetSlotCount:
                decoded.offsetSlotCount,
            records:
                decoded.records
        )
    }

    private struct DecodedCellRecords {
        let offsetSlotCount: Int

        let records:
            [NumbersNativeTableStorageProfile.CellRecord]
    }

    private struct PresentCellOffset {
        let columnIndex: Int
        let offset: Int
    }

    private static func decodeCellRecords(
        storage: [UInt8],
        offsets: [UInt8],
        offsetUnitByteCount: Int,
        layout: NumbersCellStorageLayout,
        declaredCellCount: Int,
        strings: [UInt32: String],
        context: String
    ) throws -> DecodedCellRecords {
        guard
            offsetUnitByteCount == 1
            || offsetUnitByteCount == 4
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): unsupported cell-offset unit width \(offsetUnitByteCount)"
                )
        }

        guard offsets.count.isMultiple(
            of: 2
        ) else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): cell-offset buffer has odd byte count \(offsets.count)"
                )
        }

        let offsetSlotCount =
            offsets.count / 2

        var present:
            [PresentCellOffset] = []

        present.reserveCapacity(
            declaredCellCount
        )

        for columnIndex in 0..<offsetSlotCount {
            let raw =
                try littleEndianUInt16(
                    offsets,
                    at:
                        columnIndex * 2,
                    context:
                        "\(context) column \(columnIndex) offset"
                )

            if raw == UInt16.max {
                continue
            }

            let offset =
                Int(
                    raw
                )
                * offsetUnitByteCount

            guard offset < storage.count else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): column \(columnIndex) offset \(offset) is outside \(storage.count)-byte cell-storage buffer"
                    )
            }

            present.append(
                PresentCellOffset(
                    columnIndex:
                        columnIndex,
                    offset:
                        offset
                )
            )
        }

        guard present.count == declaredCellCount else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): offset table exposes \(present.count) cells but row declares \(declaredCellCount)"
                )
        }

        let uniqueOffsets =
            Set(
                present.map(
                    \.offset
                )
            )

        guard uniqueOffsets.count == present.count else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): multiple columns reference the same cell-record offset"
                )
        }

        let orderedByOffset =
            present.sorted {
                lhs,
                rhs in

                lhs.offset < rhs.offset
            }

        var records:
            [NumbersNativeTableStorageProfile.CellRecord] = []

        records.reserveCapacity(
            orderedByOffset.count
        )

        for index in orderedByOffset.indices {
            let current =
                orderedByOffset[
                    index
                ]

            let end =
                index + 1
                    < orderedByOffset.count
                ? orderedByOffset[
                    index + 1
                ]
                .offset
                : storage.count

            guard end > current.offset else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): column \(current.columnIndex) has an empty or reversed cell-record range"
                    )
            }

            let record =
                Array(
                    storage[
                        current.offset
                        ..<
                        end
                    ]
                )

            let recordContext =
                "\(context) column \(current.columnIndex)"

            let header =
                try decodeCellRecordHeader(
                    record,
                    layout: layout,
                    context:
                        recordContext
                )

            let decodedFields:
                BNCV5Fields?

            switch layout {
            case .bncV5:
                decodedFields =
                    try decodeBNCV5Fields(
                        record,
                        fieldMask:
                            header.fieldMask,
                        context:
                            recordContext
                    )

            case .legacy:
                decodedFields = nil
            }

            let primitiveValue:
                NumbersCellValue?

            if let decodedFields {
                primitiveValue =
                    try decodePrimitiveValue(
                        type: header.type,
                        fields: decodedFields,
                        strings: strings,
                        context: recordContext
                    )
            } else {
                primitiveValue = nil
            }

            let formatReference:
                BNCFormatReference?

            if let decodedFields {
                formatReference =
                    try decodeFormatReference(
                        decodedFields,
                        cellType:
                            header.type,
                        context:
                            recordContext
                    )
            } else {
                formatReference = nil
            }

            records.append(
                NumbersNativeTableStorageProfile.CellRecord(
                    columnIndex:
                        current.columnIndex,
                    offset:
                        current.offset,
                    byteCount:
                        record.count,
                    version:
                        header.version,
                    type:
                        header.type,
                    fieldMask:
                        header.fieldMask,
                    primitiveValue:
                        primitiveValue,
                    formulaKey:
                        decodedFields?.formulaKey,
                    suggestedFormatKind:
                        decodedFields?
                            .suggestedFormatKind,
                    formatFamily:
                        formatReference?
                            .family,
                    formatKey:
                        formatReference?
                            .key,
                    controlCellSpecKey:
                        decodedFields?
                            .controlCellSpecKey,
                    unparsedTrailingByteCount:
                        decodedFields?.unparsedTrailingByteCount
                        ?? 0
                )
            )
        }

        records.sort {
            lhs,
            rhs in

            lhs.columnIndex
                < rhs.columnIndex
        }

        return DecodedCellRecords(
            offsetSlotCount:
                offsetSlotCount,
            records:
                records
        )
    }

    private struct BNCV5Fields {
        let decimal128: [UInt8]?
        let doubleValue: Double?
        let dateSeconds: Double?
        let stringKey: UInt32?
        let formulaKey: UInt32?

        let controlCellSpecKey: UInt32?
        let suggestedFormatKind: UInt32?

        let numberFormatKey: UInt32?
        let currencyFormatKey: UInt32?
        let dateFormatKey: UInt32?
        let durationFormatKey: UInt32?
        let textFormatKey: UInt32?
        let booleanFormatKey: UInt32?

        let unparsedTrailingByteCount: Int
    }

    private static func decodeBNCV5Fields(
        _ bytes: [UInt8],
        fieldMask: UInt32,
        context: String
    ) throws -> BNCV5Fields {
        let knownMask:
            UInt32 = 0x001F_FFFF

        guard fieldMask & ~knownMask == 0 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): BNC-v5 field mask contains unsupported bits 0x\(String(fieldMask & ~knownMask, radix: 16))"
                )
        }

        var cursor = 12

        var decimal128: [UInt8]?
        var doubleValue: Double?
        var dateSeconds: Double?
        var stringKey: UInt32?
        var formulaKey: UInt32?

        var controlCellSpecKey: UInt32?
        var suggestedFormatKind: UInt32?

        var numberFormatKey: UInt32?
        var currencyFormatKey: UInt32?
        var dateFormatKey: UInt32?
        var durationFormatKey: UInt32?
        var textFormatKey: UInt32?
        var booleanFormatKey: UInt32?

        let fields: [(UInt32, Int)] = [
            (0x000001, 16),
            (0x000002, 8),
            (0x000004, 8),
            (0x000008, 4),
            (0x000010, 4),
            (0x000020, 4),
            (0x000040, 4),
            (0x000080, 4),
            (0x000100, 4),
            (0x000200, 4),
            (0x000400, 4),
            (0x000800, 4),
            (0x001000, 4),
            (0x002000, 4),
            (0x004000, 4),
            (0x008000, 4),
            (0x010000, 4),
            (0x020000, 4),
            (0x040000, 4),
            (0x080000, 4),
            (0x100000, 4),
        ]

        for (bit, size) in fields {
            guard fieldMask & bit != 0 else {
                continue
            }

            guard cursor + size <= bytes.count else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): BNC-v5 field 0x\(String(bit, radix: 16)) exceeds \(bytes.count)-byte record"
                    )
            }

            switch bit {
            case 0x000001:
                decimal128 =
                    Array(
                        bytes[
                            cursor
                            ..<
                            cursor + size
                        ]
                    )

            case 0x000002:
                doubleValue =
                    try littleEndianDouble(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) double value"
                    )

            case 0x000004:
                dateSeconds =
                    try littleEndianDouble(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) datetime value"
                    )

            case 0x000008:
                stringKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) string key"
                    )

            case 0x000200:
                formulaKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) formula key"
                    )

            case 0x000400:
                controlCellSpecKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) control-cell-spec key"
                    )

            case 0x001000:
                suggestedFormatKind =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) suggested format kind"
                    )

            case 0x002000:
                numberFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) number format key"
                    )

            case 0x004000:
                currencyFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) currency format key"
                    )

            case 0x008000:
                dateFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) date format key"
                    )

            case 0x010000:
                durationFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) duration format key"
                    )

            case 0x020000:
                textFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) text format key"
                    )

            case 0x040000:
                booleanFormatKey =
                    try littleEndianUInt32(
                        bytes,
                        at: cursor,
                        context:
                            "\(context) boolean format key"
                    )

            default:
                break
            }

            cursor += size
        }

        guard cursor <= bytes.count else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): BNC-v5 field cursor exceeded record"
                )
        }

        return BNCV5Fields(
            decimal128: decimal128,
            doubleValue: doubleValue,
            dateSeconds: dateSeconds,
            stringKey: stringKey,
            formulaKey: formulaKey,
            controlCellSpecKey:
                controlCellSpecKey,
            suggestedFormatKind:
                suggestedFormatKind,
            numberFormatKey:
                numberFormatKey,
            currencyFormatKey:
                currencyFormatKey,
            dateFormatKey:
                dateFormatKey,
            durationFormatKey:
                durationFormatKey,
            textFormatKey:
                textFormatKey,
            booleanFormatKey:
                booleanFormatKey,
            unparsedTrailingByteCount:
                bytes.count - cursor
        )
    }

    private typealias BNCFormatReference =
        NumbersNativeBNCFormatReference

    private static func decodeFormatReference(
        _ fields: BNCV5Fields,
        cellType: UInt8,
        context: String
    ) throws -> BNCFormatReference? {
        var references:
            [BNCFormatReference] = []

        if let key =
            fields.numberFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .number,
                    key: key
                )
            )
        }

        if let key =
            fields.currencyFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .currency,
                    key: key
                )
            )
        }

        if let key =
            fields.dateFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .date,
                    key: key
                )
            )
        }

        if let key =
            fields.durationFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .duration,
                    key: key
                )
            )
        }

        if let key =
            fields.textFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .text,
                    key: key
                )
            )
        }

        if let key =
            fields.booleanFormatKey
        {
            references.append(
                BNCFormatReference(
                    family: .boolean,
                    key: key
                )
            )
        }

        return try NumbersNativeBNCFormatSelector.select(
            references,
            suggestedFormatKind:
                fields.suggestedFormatKind,
            cellType:
                cellType,
            controlCellSpecKey:
                fields.controlCellSpecKey,
            context:
                context
        )
    }

    private static func decodePrimitiveValue(
        type: UInt8,
        fields: BNCV5Fields,
        strings: [UInt32: String],
        context: String
    ) throws -> NumbersCellValue? {
        switch type {
        case 0:
            return .empty

        case 2, 10:
            guard let bytes = fields.decimal128 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): numeric cell type \(type) has no Decimal128 field"
                    )
            }

            return .number(
                try decimal128(
                    bytes,
                    context: context
                )
            )

        case 7:
            guard let value =
                fields.doubleValue
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): duration cell type 7 has no double value"
                    )
            }

            guard value.isFinite else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): duration cell type 7 has non-finite double value"
                    )
            }

            return .number(
                Decimal(
                    value
                )
            )

        case 3:
            guard let key = fields.stringKey else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): text cell has no shared-string key"
                    )
            }

            guard let value = strings[key] else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): shared-string key \(key) is missing"
                    )
            }

            return .text(
                value
            )

        case 5:
            guard let seconds = fields.dateSeconds else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): date cell has no datetime field"
                    )
            }

            return .date(
                try dateFromNumbersWallClock(
                    seconds,
                    timeZone: .current,
                    context: context
                )
            )

        case 6:
            guard let value = fields.doubleValue else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): boolean cell has no double field"
                    )
            }

            return .boolean(
                value > 0
            )

        case 8, 9:
            return nil

        default:
            return nil
        }
    }

    private static func dateFromNumbersWallClock(
        _ seconds: Double,
        timeZone: TimeZone,
        context: String
    ) throws -> Date {
        guard seconds.isFinite else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): datetime value is not finite"
                )
        }

        guard let utc =
            TimeZone(
                secondsFromGMT: 0
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): could not construct UTC timezone"
                )
        }

        let encodedWallClock =
            Date(
                timeIntervalSinceReferenceDate:
                    seconds
            )

        var encodedCalendar =
            Calendar(
                identifier: .gregorian
            )

        encodedCalendar.timeZone =
            utc

        let components =
            encodedCalendar.dateComponents(
                [
                    .era,
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second,
                    .nanosecond,
                ],
                from:
                    encodedWallClock
            )

        var localCalendar =
            Calendar(
                identifier: .gregorian
            )

        localCalendar.timeZone =
            timeZone

        var wallClock =
            DateComponents()

        wallClock.calendar =
            localCalendar

        wallClock.timeZone =
            timeZone

        wallClock.era =
            components.era

        wallClock.year =
            components.year

        wallClock.month =
            components.month

        wallClock.day =
            components.day

        wallClock.hour =
            components.hour

        wallClock.minute =
            components.minute

        wallClock.second =
            components.second

        wallClock.nanosecond =
            components.nanosecond

        guard let result =
            localCalendar.date(
                from:
                    wallClock
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): Numbers wall-clock datetime could not be represented in timezone \(timeZone.identifier)"
                )
        }

        return result
    }

    private static func decimal128(
        _ bytes: [UInt8],
        context: String
    ) throws -> Decimal {
        guard bytes.count == 16 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): Decimal128 field is \(bytes.count) bytes"
                )
        }

        let exponent =
            (Int(bytes[15] & 0x7F) << 7)
            | Int(bytes[14] >> 1)

        var coefficient =
            Decimal(
                Int(
                    bytes[14] & 0x01
                )
            )

        for index in stride(
            from: 13,
            through: 0,
            by: -1
        ) {
            coefficient *= 256
            coefficient +=
                Decimal(
                    Int(
                        bytes[index]
                    )
                )
        }

        if bytes[15] & 0x80 != 0 {
            coefficient *= -1
        }

        let power =
            exponent - 0x1820

        guard let decimalPower =
            Int16(
                exactly:
                    power
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): Decimal128 exponent \(power) does not fit Int16"
                )
        }

        var result =
            Decimal()

        var source =
            coefficient

        let calculation =
            NSDecimalMultiplyByPowerOf10(
                &result,
                &source,
                decimalPower,
                .plain
            )

        guard calculation == .noError else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): Decimal128 conversion failed with \(calculation)"
                )
        }

        return result
    }

    private static func decodeStringTable(
        reference: UInt64,
        tableName: String,
        store: NumbersObjectStore
    ) throws -> [UInt32: String] {
        let message =
            try store.message(
                identifier: reference,
                type: tableDataListType,
                context:
                    "TST.DataStore \(tableName) stringTable"
            )

        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.TableDataList stringTable"
            )

        guard
            let listType =
                fields.first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint,
            listType == 1
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.DataStore \(tableName) stringTable is not a STRING TableDataList"
                )
        }

        var result:
            [UInt32: String] = [:]

        for field in fields where
            field.number == 3
            && field.wireType == 2
        {
            let entryFields =
                try NumbersWire.decode(
                    field.bytes,
                    context:
                        "TST.TableDataList.ListEntry"
                )

            guard
                let rawKey =
                    entryFields.first(
                        where: {
                            $0.number == 1
                            && $0.wireType == 0
                        }
                    )?
                    .varint,
                let key =
                    UInt32(
                        exactly:
                            rawKey
                    )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TableDataList.ListEntry missing valid key"
                    )
            }

            guard
                let stringField =
                    entryFields.first(
                        where: {
                            $0.number == 3
                            && $0.wireType == 2
                        }
                    ),
                let value =
                    String(
                        bytes: stringField.bytes,
                        encoding: .utf8
                    )
            else {
                continue
            }

            guard result[key] == nil else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TableDataList contains duplicate string key \(key)"
                    )
            }

            result[key] =
                value
        }

        return result
    }

    private struct CellRecordHeader {
        let version: UInt8
        let type: UInt8
        let fieldMask: UInt32
    }

    private static func decodeCellRecordHeader(
        _ bytes: [UInt8],
        layout: NumbersCellStorageLayout,
        context: String
    ) throws -> CellRecordHeader {
        guard let version =
            bytes.first
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): empty cell record"
                )
        }

        switch layout {
        case .bncV5:
            guard version == 5 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): modern cell record has unsupported BNC version \(version)"
                    )
            }

            guard bytes.count >= 12 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): BNC-v5 cell record is only \(bytes.count) bytes"
                    )
            }

            return CellRecordHeader(
                version: version,
                type:
                    bytes[
                        1
                    ],
                fieldMask:
                    try littleEndianUInt32(
                        bytes,
                        at: 8,
                        context:
                            "\(context) BNC-v5 field mask"
                    )
            )

        case .legacy:
            switch version {
            case 0, 1:
                guard bytes.count >= 8 else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "\(context): legacy-v\(version) cell record is only \(bytes.count) bytes"
                        )
                }

                return CellRecordHeader(
                    version: version,
                    type:
                        bytes[
                            2
                        ],
                    fieldMask:
                        UInt32(
                            try littleEndianUInt16(
                                bytes,
                                at: 4,
                                context:
                                    "\(context) legacy-v\(version) field mask"
                            )
                        )
                )

            case 2, 3:
                guard bytes.count >= 12 else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "\(context): legacy-v\(version) cell record is only \(bytes.count) bytes"
                        )
                }

                return CellRecordHeader(
                    version: version,
                    type:
                        bytes[
                            2
                        ],
                    fieldMask:
                        try littleEndianUInt32(
                            bytes,
                            at: 4,
                            context:
                                "\(context) legacy-v\(version) field mask"
                        )
                )

            case 4:
                guard bytes.count >= 12 else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "\(context): legacy-v4 cell record is only \(bytes.count) bytes"
                        )
                }

                return CellRecordHeader(
                    version: version,
                    type:
                        bytes[
                            1
                        ],
                    fieldMask:
                        try littleEndianUInt32(
                            bytes,
                            at: 4,
                            context:
                                "\(context) legacy-v4 field mask"
                        )
                )

            default:
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): unsupported legacy cell-storage version \(version)"
                    )
            }
        }
    }

    private static func littleEndianUInt16(
        _ bytes: [UInt8],
        at index: Int,
        context: String
    ) throws -> UInt16 {
        guard
            index >= 0,
            index + 2 <= bytes.count
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): UInt16 exceeds buffer"
                )
        }

        return UInt16(
            bytes[
                index
            ]
        )
        | (
            UInt16(
                bytes[
                    index + 1
                ]
            )
            << 8
        )
    }

    private static func littleEndianDouble(
        _ bytes: [UInt8],
        at index: Int,
        context: String
    ) throws -> Double {
        Double(
            bitPattern:
                try littleEndianUInt64(
                    bytes,
                    at: index,
                    context: context
                )
        )
    }

    private static func littleEndianUInt64(
        _ bytes: [UInt8],
        at index: Int,
        context: String
    ) throws -> UInt64 {
        guard
            index >= 0,
            index + 8 <= bytes.count
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): UInt64 exceeds buffer"
                )
        }

        var value:
            UInt64 = 0

        for byteOffset in 0..<8 {
            value |=
                UInt64(
                    bytes[
                        index + byteOffset
                    ]
                )
                << UInt64(
                    byteOffset * 8
                )
        }

        return value
    }

    private static func littleEndianUInt32(
        _ bytes: [UInt8],
        at index: Int,
        context: String
    ) throws -> UInt32 {
        guard
            index >= 0,
            index + 4 <= bytes.count
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): UInt32 exceeds buffer"
                )
        }

        return UInt32(
            bytes[
                index
            ]
        )
        | (
            UInt32(
                bytes[
                    index + 1
                ]
            )
            << 8
        )
        | (
            UInt32(
                bytes[
                    index + 2
                ]
            )
            << 16
        )
        | (
            UInt32(
                bytes[
                    index + 3
                ]
            )
            << 24
        )
    }

    private static func requiredString(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> String {
        guard
            let field =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 2
                    }
                ),
            let value =
                String(
                    bytes: field.bytes,
                    encoding: .utf8
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): missing or invalid UTF-8 string"
                )
        }

        return value
    }

    private static func requiredInt(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> Int {
        guard
            let raw =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 0
                    }
                )?
                .varint,
            let value =
                Int(
                    exactly:
                        raw
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): missing or invalid integer"
                )
        }

        return value
    }

    private static func optionalInt(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> Int? {
        guard
            let field =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 0
                    }
                )
        else {
            return nil
        }

        guard
            let raw =
                field.varint,
            let value =
                Int(
                    exactly:
                        raw
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): invalid integer"
                )
        }

        return value
    }

    private static func optionalBool(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> Bool? {
        guard
            let field =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 0
                    }
                )
        else {
            return nil
        }

        guard
            let raw = field.varint,
            raw == 0
            || raw == 1
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): invalid boolean"
                )
        }

        return raw == 1
    }

    private static func bytesField(
        _ fields: [NumbersWire.Field],
        number: UInt64
    ) -> [UInt8]? {
        fields.first(
            where: {
                $0.number == number
                && $0.wireType == 2
            }
        )?
        .bytes
    }

    private static func optionalReference(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> UInt64? {
        guard
            let field =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 2
                    }
                )
        else {
            return nil
        }

        return try reference(
            field.bytes,
            context: context
        )
    }

    private static func reference(
        _ bytes: [UInt8],
        context: String
    ) throws -> UInt64 {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "\(context) TSP.Reference"
            )

        guard
            let identifier =
                fields.first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): missing reference identifier"
                )
        }

        return identifier
    }
}
