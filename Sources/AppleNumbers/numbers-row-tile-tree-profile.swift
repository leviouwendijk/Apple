import Foundation

@_spi(Testing)
public struct NumbersNativeRowTileTreeProfile:
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
        public let name: String
        public let tableModelIdentifier: UInt64

        public let tileStorageFieldSignatures: [String]
        public let rowTileTreeFieldSignatures: [String]

        public let tileLinks: [TileLink]
        public let nodes: [Node]

        public init(
            name: String,
            tableModelIdentifier: UInt64,
            tileStorageFieldSignatures: [String],
            rowTileTreeFieldSignatures: [String],
            tileLinks: [TileLink],
            nodes: [Node]
        ) {
            self.name =
                name

            self.tableModelIdentifier =
                tableModelIdentifier

            self.tileStorageFieldSignatures =
                tileStorageFieldSignatures

            self.rowTileTreeFieldSignatures =
                rowTileTreeFieldSignatures

            self.tileLinks =
                tileLinks

            self.nodes =
                nodes
        }
    }

    public struct TileLink:
        Equatable,
        Sendable
    {
        public let arrayIndex: Int
        public let tileID: UInt64
        public let objectIdentifier: UInt64
        public let fieldSignatures: [String]

        public init(
            arrayIndex: Int,
            tileID: UInt64,
            objectIdentifier: UInt64,
            fieldSignatures: [String]
        ) {
            self.arrayIndex =
                arrayIndex

            self.tileID =
                tileID

            self.objectIdentifier =
                objectIdentifier

            self.fieldSignatures =
                fieldSignatures
        }
    }

    public struct Node:
        Equatable,
        Sendable
    {
        public let key: Int
        public let value: Int
        public let fieldSignatures: [String]

        public init(
            key: Int,
            value: Int,
            fieldSignatures: [String]
        ) {
            self.key =
                key

            self.value =
                value

            self.fieldSignatures =
                fieldSignatures
        }
    }
}

@_spi(Testing)
public struct NumbersNativePlacedRow:
    Equatable,
    Sendable
{
    public let globalRowIndex: Int

    public let tileBaseRowIndex: Int
    public let tileArrayIndex: Int

    public let tileID: UInt64
    public let tileObjectIdentifier: UInt64

    public let tileRowIndex: Int

    public let row:
        NumbersNativeTableStorageProfile.Row

    public init(
        globalRowIndex: Int,
        tileBaseRowIndex: Int,
        tileArrayIndex: Int,
        tileID: UInt64,
        tileObjectIdentifier: UInt64,
        tileRowIndex: Int,
        row: NumbersNativeTableStorageProfile.Row
    ) {
        self.globalRowIndex =
            globalRowIndex

        self.tileBaseRowIndex =
            tileBaseRowIndex

        self.tileArrayIndex =
            tileArrayIndex

        self.tileID =
            tileID

        self.tileObjectIdentifier =
            tileObjectIdentifier

        self.tileRowIndex =
            tileRowIndex

        self.row =
            row
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func rowTileTreeProfile(
        at documentURL: URL
    ) throws -> NumbersNativeRowTileTreeProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeRowTileTreeProfiler.decode(
            messages
        )
    }
}

@_spi(Testing)
public extension NumbersNativeTableStorageProfile.Table {
    func placedRows(
        using rowTree:
            NumbersNativeRowTileTreeProfile.Table
    ) throws -> [NumbersNativePlacedRow] {
        guard
            tableModelIdentifier
                == rowTree.tableModelIdentifier
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "row-placement table identity mismatch: storage=\(tableModelIdentifier), tree=\(rowTree.tableModelIdentifier)"
                )
        }

        guard name == rowTree.name else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "row-placement table name mismatch for model \(tableModelIdentifier): storage=\(name), tree=\(rowTree.name)"
                )
        }

        guard tiles.count == rowTree.tileLinks.count else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(name) has \(tiles.count) decoded tiles but row tree describes \(rowTree.tileLinks.count) TileStorage entries"
                )
        }

        for (
            arrayIndex,
            tile
        ) in tiles.enumerated() {
            let link =
                rowTree.tileLinks[
                    arrayIndex
                ]

            guard
                link.arrayIndex == arrayIndex,
                link.tileID == tile.tileID,
                link.objectIdentifier
                    == tile.objectIdentifier
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(name) TileStorage array index \(arrayIndex) does not preserve tile identity"
                    )
            }
        }

        var placed:
            [NumbersNativePlacedRow] = []

        var occupiedGlobalRows:
            Set<Int> = []

        for node in rowTree.nodes {
            guard
                node.value >= 0,
                node.value < tiles.count
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(name) rowTileTree node key \(node.key) references TileStorage index \(node.value) outside 0..<\(tiles.count)"
                    )
            }

            let tile =
                tiles[
                    node.value
                ]

            for row in tile.rows {
                let (
                    globalRowIndex,
                    overflow
                ) =
                    node.key
                        .addingReportingOverflow(
                            row.tileRowIndex
                        )

                guard
                    !overflow,
                    globalRowIndex >= 0
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "table \(name) rowTileTree base \(node.key) plus tile row \(row.tileRowIndex) overflows global row space"
                        )
                }

                guard occupiedGlobalRows.insert(
                    globalRowIndex
                )
                .inserted else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "table \(name) resolves more than one tile row to global row \(globalRowIndex)"
                        )
                }

                placed.append(
                    NumbersNativePlacedRow(
                        globalRowIndex:
                            globalRowIndex,
                        tileBaseRowIndex:
                            node.key,
                        tileArrayIndex:
                            node.value,
                        tileID:
                            tile.tileID,
                        tileObjectIdentifier:
                            tile.objectIdentifier,
                        tileRowIndex:
                            row.tileRowIndex,
                        row:
                            row
                    )
                )
            }
        }

        placed.sort {
            lhs,
            rhs in

            lhs.globalRowIndex
                < rhs.globalRowIndex
        }

        return placed
    }
}

enum NumbersNativeRowTileTreeProfiler {
    static let tableModelType:
        UInt32 = 6001

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeRowTileTreeProfile {
        var tables:
            [NumbersNativeRowTileTreeProfile.Table] = []

        for tableModel in messages where
            tableModel.type == tableModelType
        {
            let tableFields =
                try NumbersWire.decode(
                    tableModel.payload,
                    context:
                        "TST.TableModelArchive rowTileTree profile"
                )

            let tableName =
                try requiredString(
                    tableFields,
                    number: 8,
                    context:
                        "TST.TableModelArchive.table_name"
                )

            guard let dataStore =
                tableFields.first(
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
                        "TST.DataStore \(tableName) rowTileTree profile"
                )

            guard let tileStorage =
                dataStoreFields.first(
                    where: {
                        $0.number == 3
                        && $0.wireType == 2
                    }
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.DataStore \(tableName) missing TileStorage field 3"
                    )
            }

            guard let rowTileTree =
                dataStoreFields.first(
                    where: {
                        $0.number == 9
                        && $0.wireType == 2
                    }
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.DataStore \(tableName) missing rowTileTree field 9"
                    )
            }

            let decodedTileStorage =
                try decodeTileStorage(
                    tileStorage.bytes,
                    tableName:
                        tableName
                )

            let decodedRowTree =
                try decodeRowTileTree(
                    rowTileTree.bytes,
                    tableName:
                        tableName
                )

            tables.append(
                NumbersNativeRowTileTreeProfile.Table(
                    name:
                        tableName,
                    tableModelIdentifier:
                        tableModel.identifier,
                    tileStorageFieldSignatures:
                        decodedTileStorage
                            .fieldSignatures,
                    rowTileTreeFieldSignatures:
                        decodedRowTree
                            .fieldSignatures,
                    tileLinks:
                        decodedTileStorage
                            .tileLinks,
                    nodes:
                        decodedRowTree
                            .nodes
                )
            )
        }

        return NumbersNativeRowTileTreeProfile(
            tables:
                tables.sorted {
                    if $0.name != $1.name {
                        return $0.name
                            < $1.name
                    }

                    return $0.tableModelIdentifier
                        < $1.tableModelIdentifier
                }
        )
    }

    private struct DecodedTileStorage {
        let fieldSignatures:
            [String]

        let tileLinks:
            [NumbersNativeRowTileTreeProfile.TileLink]
    }

    private static func decodeTileStorage(
        _ bytes: [UInt8],
        tableName: String
    ) throws -> DecodedTileStorage {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TileStorage \(tableName) row placement"
            )

        let tileFields =
            fields.filter {
                $0.number == 1
                && $0.wireType == 2
            }

        var tileLinks:
            [NumbersNativeRowTileTreeProfile.TileLink] = []

        tileLinks.reserveCapacity(
            tileFields.count
        )

        for (
            arrayIndex,
            field
        ) in tileFields.enumerated() {
            let fields =
                try NumbersWire.decode(
                    field.bytes,
                    context:
                        "TST.TileStorage.Tile \(tableName) index \(arrayIndex)"
                )

            guard let tileID =
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
                        "TST.TileStorage \(tableName) index \(arrayIndex) missing tileid"
                    )
            }

            guard let referenceField =
                fields.first(
                    where: {
                        $0.number == 2
                        && $0.wireType == 2
                    }
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TileStorage \(tableName) tile \(tileID) missing object reference"
                    )
            }

            tileLinks.append(
                NumbersNativeRowTileTreeProfile.TileLink(
                    arrayIndex:
                        arrayIndex,
                    tileID:
                        tileID,
                    objectIdentifier:
                        try reference(
                            referenceField.bytes,
                            context:
                                "TST.TileStorage \(tableName) tile \(tileID)"
                        ),
                    fieldSignatures:
                        signatures(
                            fields
                        )
                )
            )
        }

        return DecodedTileStorage(
            fieldSignatures:
                signatures(
                    fields
                ),
            tileLinks:
                tileLinks
        )
    }

    private struct DecodedRowTree {
        let fieldSignatures:
            [String]

        let nodes:
            [NumbersNativeRowTileTreeProfile.Node]
    }

    private static func decodeRowTileTree(
        _ bytes: [UInt8],
        tableName: String
    ) throws -> DecodedRowTree {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TableRBTree \(tableName)"
            )

        var nodes:
            [NumbersNativeRowTileTreeProfile.Node] = []

        for field in fields where
            field.number == 1
            && field.wireType == 2
        {
            let nodeFields =
                try NumbersWire.decode(
                    field.bytes,
                    context:
                        "TST.TableRBTree.Node \(tableName)"
                )

            guard
                let rawKey =
                    nodeFields.first(
                        where: {
                            $0.number == 1
                            && $0.wireType == 0
                        }
                    )?
                    .varint,
                let key =
                    Int(
                        exactly:
                            rawKey
                    )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TableRBTree.Node \(tableName) missing valid row-offset key"
                    )
            }

            guard
                let rawValue =
                    nodeFields.first(
                        where: {
                            $0.number == 2
                            && $0.wireType == 0
                        }
                    )?
                    .varint,
                let value =
                    Int(
                        exactly:
                            rawValue
                    )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TableRBTree.Node \(tableName) key \(key) missing valid TileStorage index"
                    )
            }

            nodes.append(
                NumbersNativeRowTileTreeProfile.Node(
                    key:
                        key,
                    value:
                        value,
                    fieldSignatures:
                        signatures(
                            nodeFields
                        )
                )
            )
        }

        guard !nodes.isEmpty else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableRBTree \(tableName) contains no row nodes"
                )
        }

        let distinctKeys =
            Set(
                nodes.map(
                    \.key
                )
            )

        guard distinctKeys.count == nodes.count else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableRBTree \(tableName) contains duplicate row-offset keys"
                )
        }

        return DecodedRowTree(
            fieldSignatures:
                signatures(
                    fields
                ),
            nodes:
                nodes
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
                    bytes:
                        field.bytes,
                    encoding:
                        .utf8
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): missing or invalid UTF-8 string"
                )
        }

        return value
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

        guard let identifier =
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
                    "\(context): TSP.Reference missing identifier"
                )
        }

        return identifier
    }

    private static func signatures(
        _ fields: [NumbersWire.Field]
    ) -> [String] {
        fields.map {
            "\($0.number)/\($0.wireType)"
        }
    }
}
