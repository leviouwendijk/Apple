import Foundation

@_spi(Testing)
public struct NumbersNativeDocumentGraph:
    Sendable
{
    public let sheets: [Sheet]

    public init(
        sheets: [Sheet]
    ) {
        self.sheets =
            sheets
    }

    public struct Sheet:
        Sendable
    {
        public let identifier: UInt64
        public let name: String
        public let tables: [Table]

        public init(
            identifier: UInt64,
            name: String,
            tables: [Table]
        ) {
            self.identifier =
                identifier

            self.name =
                name

            self.tables =
                tables
        }
    }

    public struct Table:
        Sendable
    {
        public let tableInfoIdentifier: UInt64
        public let tableModelIdentifier: UInt64

        public let name: String

        public let rowCount: Int
        public let columnCount: Int

        public let headerRowCount: Int
        public let headerColumnCount: Int
        public let footerRowCount: Int

        public let storage:
            NumbersNativeTableStorageProfile.Table

        public let rowTileTree:
            NumbersNativeRowTileTreeProfile.Table

        public let placedRows:
            [NumbersNativePlacedRow]

        public let formulas:
            NumbersNativeFormulaProfile.Table?

        public let modernDataLists:
            NumbersNativeModernDataListProfile.Table

        public init(
            tableInfoIdentifier: UInt64,
            tableModelIdentifier: UInt64,
            name: String,
            rowCount: Int,
            columnCount: Int,
            headerRowCount: Int,
            headerColumnCount: Int,
            footerRowCount: Int,
            storage: NumbersNativeTableStorageProfile.Table,
            rowTileTree: NumbersNativeRowTileTreeProfile.Table,
            placedRows: [NumbersNativePlacedRow],
            formulas: NumbersNativeFormulaProfile.Table?,
            modernDataLists: NumbersNativeModernDataListProfile.Table
        ) {
            self.tableInfoIdentifier =
                tableInfoIdentifier

            self.tableModelIdentifier =
                tableModelIdentifier

            self.name =
                name

            self.rowCount =
                rowCount

            self.columnCount =
                columnCount

            self.headerRowCount =
                headerRowCount

            self.headerColumnCount =
                headerColumnCount

            self.footerRowCount =
                footerRowCount

            self.storage =
                storage

            self.rowTileTree =
                rowTileTree

            self.placedRows =
                placedRows

            self.formulas =
                formulas

            self.modernDataLists =
                modernDataLists
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func nativeDocumentGraph(
        at documentURL: URL
    ) throws -> NumbersNativeDocumentGraph {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        let store =
            NumbersObjectStore(
                messages
            )

        let structure =
            try NumbersNativeStructureDecoder.decode(
                messages,
                store: store
            )

        let storage =
            try NumbersTileStorageDecoder.decode(
                messages,
                store: store
            )

        let rowTileTrees =
            try NumbersNativeRowTileTreeProfiler.decode(
                messages
            )

        let formulas =
            try NumbersNativeFormulaProfiler.decode(
                messages,
                store: store
            )

        let modernDataLists =
            try NumbersNativeModernDataListProfiler.decode(
                messages,
                store: store
            )

        return try NumbersNativeDocumentGraphDecoder.decode(
            structure:
                structure,
            storage:
                storage,
            rowTileTrees:
                rowTileTrees,
            formulas:
                formulas,
            modernDataLists:
                modernDataLists
        )
    }
}

private enum NumbersNativeDocumentGraphDecoder {
    static func decode(
        structure: NumbersNativeDocumentStructure,
        storage: NumbersNativeTableStorageProfile,
        rowTileTrees: NumbersNativeRowTileTreeProfile,
        formulas: NumbersNativeFormulaProfile,
        modernDataLists: NumbersNativeModernDataListProfile
    ) throws -> NumbersNativeDocumentGraph {
        var seenTableModelIdentifiers:
            Set<UInt64> = []

        let sheets =
            try structure.sheets.map {
                sheet in

                let tables =
                    try sheet.tables.map {
                        structureTable in

                        guard seenTableModelIdentifiers.insert(
                            structureTable
                                .tableModelIdentifier
                        )
                        .inserted else {
                            throw NumbersObjectGraphError
                                .invalidObjectGraph(
                                    "table model \(structureTable.tableModelIdentifier) appears more than once in document sheet ordering"
                                )
                        }

                        let storageTable =
                            try uniqueStorageTable(
                                identifier:
                                    structureTable
                                        .tableModelIdentifier,
                                profile:
                                    storage
                            )

                        let rowTileTree =
                            try uniqueRowTileTree(
                                identifier:
                                    structureTable
                                        .tableModelIdentifier,
                                profile:
                                    rowTileTrees
                            )

                        let modernDataListTable =
                            try uniqueModernDataListTable(
                                identifier:
                                    structureTable
                                        .tableModelIdentifier,
                                profile:
                                    modernDataLists
                            )

                        let formulaTable =
                            try optionalFormulaTable(
                                identifier:
                                    structureTable
                                        .tableModelIdentifier,
                                profile:
                                    formulas
                            )

                        try validateNames(
                            structure:
                                structureTable,
                            storage:
                                storageTable,
                            rowTileTree:
                                rowTileTree,
                            formulas:
                                formulaTable,
                            modernDataLists:
                                modernDataListTable
                        )

                        let placedRows =
                            try storageTable.placedRows(
                                using:
                                    rowTileTree
                            )

                        return NumbersNativeDocumentGraph.Table(
                            tableInfoIdentifier:
                                structureTable
                                    .tableInfoIdentifier,
                            tableModelIdentifier:
                                structureTable
                                    .tableModelIdentifier,
                            name:
                                structureTable
                                    .name,
                            rowCount:
                                structureTable
                                    .rowCount,
                            columnCount:
                                structureTable
                                    .columnCount,
                            headerRowCount:
                                structureTable
                                    .headerRowCount,
                            headerColumnCount:
                                structureTable
                                    .headerColumnCount,
                            footerRowCount:
                                structureTable
                                    .footerRowCount,
                            storage:
                                storageTable,
                            rowTileTree:
                                rowTileTree,
                            placedRows:
                                placedRows,
                            formulas:
                                formulaTable,
                            modernDataLists:
                                modernDataListTable
                        )
                    }

                return NumbersNativeDocumentGraph.Sheet(
                    identifier:
                        sheet.identifier,
                    name:
                        sheet.name,
                    tables:
                        tables
                )
            }

        let orderedTableCount =
            sheets.reduce(
                0
            ) {
                $0 + $1.tables.count
            }

        guard
            orderedTableCount
                == storage.tables.count,
            orderedTableCount
                == rowTileTrees.tables.count,
            orderedTableCount
                == modernDataLists.tables.count
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "consolidated native graph table counts disagree: ordered=\(orderedTableCount), storage=\(storage.tables.count), rowTree=\(rowTileTrees.tables.count), modernDataLists=\(modernDataLists.tables.count)"
                )
        }

        let unknownFormulaTables =
            formulas.tables.filter {
                !seenTableModelIdentifiers.contains(
                    $0.tableModelIdentifier
                )
            }

        guard unknownFormulaTables.isEmpty else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula profile contains \(unknownFormulaTables.count) table models outside document sheet ordering"
                )
        }

        return NumbersNativeDocumentGraph(
            sheets:
                sheets
        )
    }

    private static func uniqueStorageTable(
        identifier: UInt64,
        profile: NumbersNativeTableStorageProfile
    ) throws -> NumbersNativeTableStorageProfile.Table {
        let matches =
            profile.tables.filter {
                $0.tableModelIdentifier
                    == identifier
            }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table model \(identifier) resolves to \(matches.count) storage tables"
                )
        }

        return matches[0]
    }

    private static func uniqueRowTileTree(
        identifier: UInt64,
        profile: NumbersNativeRowTileTreeProfile
    ) throws -> NumbersNativeRowTileTreeProfile.Table {
        let matches =
            profile.tables.filter {
                $0.tableModelIdentifier
                    == identifier
            }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table model \(identifier) resolves to \(matches.count) rowTileTrees"
                )
        }

        return matches[0]
    }

    private static func uniqueModernDataListTable(
        identifier: UInt64,
        profile: NumbersNativeModernDataListProfile
    ) throws -> NumbersNativeModernDataListProfile.Table {
        let matches =
            profile.tables.filter {
                $0.tableModelIdentifier
                    == identifier
            }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table model \(identifier) resolves to \(matches.count) modern DataList tables"
                )
        }

        return matches[0]
    }

    private static func optionalFormulaTable(
        identifier: UInt64,
        profile: NumbersNativeFormulaProfile
    ) throws -> NumbersNativeFormulaProfile.Table? {
        let matches =
            profile.tables.filter {
                $0.tableModelIdentifier
                    == identifier
            }

        guard matches.count <= 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table model \(identifier) resolves to \(matches.count) formula tables"
                )
        }

        return matches.first
    }

    private static func validateNames(
        structure: NumbersNativeDocumentStructure.Table,
        storage: NumbersNativeTableStorageProfile.Table,
        rowTileTree: NumbersNativeRowTileTreeProfile.Table,
        formulas: NumbersNativeFormulaProfile.Table?,
        modernDataLists: NumbersNativeModernDataListProfile.Table
    ) throws {
        let observedNames =
            [
                storage.name,
                rowTileTree.name,
                modernDataLists.name,
            ]
            + (
                formulas.map {
                    [
                        $0.name,
                    ]
                }
                ?? []
            )

        guard observedNames.allSatisfy({
            $0 == structure.name
        }) else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table model \(structure.tableModelIdentifier) name disagreement: structure=\(structure.name), joined=\(observedNames.joined(separator: ","))"
                )
        }
    }
}
