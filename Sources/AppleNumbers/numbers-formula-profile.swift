import Foundation

@_spi(Testing)
public struct NumbersNativeFormulaProfile:
    Sendable
{
    public let tables: [Table]

    public init(
        tables: [Table]
    ) {
        self.tables = tables
    }

    public struct Table:
        Sendable
    {
        public let tableModelIdentifier: UInt64
        public let name: String
        public let formulaTableReference: UInt64
        public let formulas: [Formula]

        public init(
            tableModelIdentifier: UInt64,
            name: String,
            formulaTableReference: UInt64,
            formulas: [Formula]
        ) {
            self.tableModelIdentifier =
                tableModelIdentifier

            self.name = name
            self.formulaTableReference = formulaTableReference
            self.formulas = formulas
        }
    }

    public struct Formula:
        Sendable
    {
        public let key: UInt32

        public let hostColumn: UInt64?
        public let hostRow: UInt64?

        public let fieldSignatures: [String]
        public let nodes: [Node]

        public init(
            key: UInt32,
            hostColumn: UInt64?,
            hostRow: UInt64?,
            fieldSignatures: [String],
            nodes: [Node]
        ) {
            self.key = key
            self.hostColumn = hostColumn
            self.hostRow = hostRow
            self.fieldSignatures = fieldSignatures
            self.nodes = nodes
        }
    }

    public struct Node:
        Sendable
    {
        public let type: UInt64?

        public let fieldSignatures: [String]

        public let numberValue: Double?

        public let column: Coordinate?
        public let row: Coordinate?

        public init(
            type: UInt64?,
            fieldSignatures: [String],
            numberValue: Double?,
            column: Coordinate?,
            row: Coordinate?
        ) {
            self.type = type
            self.fieldSignatures = fieldSignatures
            self.numberValue = numberValue
            self.column = column
            self.row = row
        }
    }

    public struct Coordinate:
        Sendable
    {
        public let rawValue: Int64?
        public let absolute: Bool?

        public let fieldSignatures: [String]

        public init(
            rawValue: Int64?,
            absolute: Bool?,
            fieldSignatures: [String]
        ) {
            self.rawValue = rawValue
            self.absolute = absolute
            self.fieldSignatures = fieldSignatures
        }
    }
} 

@_spi(Testing)
public extension NumbersNativeFormulaProfile.Formula {
    func source(
        hostRow: Int,
        hostColumn: Int
    ) throws -> String {
        try NumbersNativeFormulaRenderer.render(
            self,
            hostRow: hostRow,
            hostColumn: hostColumn
        )
    }
}

private enum NumbersNativeFormulaRenderer {
    static func render(
        _ formula: NumbersNativeFormulaProfile.Formula,
        hostRow: Int,
        hostColumn: Int
    ) throws -> String {
        guard hostRow > 0, hostColumn > 0 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula host coordinate must be one-based and positive"
                )
        }

        var stack:
            [String] = []

        for node in formula.nodes {
            guard let type =
                node.type
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "formula key \(formula.key) contains an AST node without a type"
                    )
            }

            switch type {
            case 36:
                guard
                    let column = node.column,
                    let row = node.row
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "formula key \(formula.key) cell-reference node is missing row/column coordinates"
                        )
                }

                let resolvedColumn =
                    try resolveRelativeCoordinate(
                        column,
                        host: hostColumn,
                        axis: "column",
                        formulaKey: formula.key
                    )

                let resolvedRow =
                    try resolveRelativeCoordinate(
                        row,
                        host: hostRow,
                        axis: "row",
                        formulaKey: formula.key
                    )

                stack.append(
                    try a1Reference(
                        row: resolvedRow,
                        column: resolvedColumn
                    )
                )

            case 17:
                guard let number =
                    node.numberValue
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "formula key \(formula.key) numeric-literal node has no number value"
                        )
                }

                stack.append(
                    try renderNumber(
                        number,
                        formulaKey: formula.key
                    )
                )

            case 3:
                guard stack.count >= 2 else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "formula key \(formula.key) multiplication node has fewer than two operands"
                        )
                }

                let rhs =
                    stack.removeLast()

                let lhs =
                    stack.removeLast()

                stack.append(
                    lhs
                    + "×"
                    + rhs
                )

            default:
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "formula key \(formula.key) contains unsupported AST node type \(type)"
                    )
            }
        }

        guard stack.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formula.key) rendered to \(stack.count) stack values instead of one"
                )
        }

        return "="
            + stack[0]
    }

    private static func resolveRelativeCoordinate(
        _ coordinate: NumbersNativeFormulaProfile.Coordinate,
        host: Int,
        axis: String,
        formulaKey: UInt32
    ) throws -> Int {
        guard
            let raw = coordinate.rawValue,
            let absolute = coordinate.absolute
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formulaKey) \(axis) coordinate is incomplete"
                )
        }

        guard absolute == false else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formulaKey) absolute \(axis) coordinates are not characterized yet"
                )
        }

        guard let delta =
            Int(
                exactly: raw
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formulaKey) \(axis) offset does not fit Int"
                )
        }

        let (
            resolved,
            overflow
        ) =
            host.addingReportingOverflow(
                delta
            )

        guard
            !overflow,
            resolved > 0
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formulaKey) resolves \(axis) outside the positive worksheet coordinate space"
                )
        }

        return resolved
    }

    private static func a1Reference(
        row: Int,
        column: Int
    ) throws -> String {
        guard row > 0, column > 0 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "A1 reference requires positive row and column"
                )
        }

        var remaining =
            column

        var scalars:
            [UnicodeScalar] = []

        while remaining > 0 {
            let zeroBased =
                remaining - 1

            let remainder =
                zeroBased % 26

            guard let scalar =
                UnicodeScalar(
                    65 + remainder
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "could not render A1 column \(column)"
                    )
            }

            scalars.append(
                scalar
            )

            remaining =
                zeroBased / 26
        }

        return String(
            String.UnicodeScalarView(
                scalars.reversed()
            )
        )
        + String(
            row
        )
    }

    private static func renderNumber(
        _ number: Double,
        formulaKey: UInt32
    ) throws -> String {
        guard number.isFinite else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula key \(formulaKey) contains a non-finite numeric literal"
                )
        }

        if let integer =
            Int64(
                exactly: number
            )
        {
            return String(
                integer
            )
        }

        return String(
            number
        )
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func formulaProfile(
        at documentURL: URL
    ) throws -> NumbersNativeFormulaProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeFormulaProfiler.decode(
            messages
        )
    }
}

enum NumbersNativeFormulaProfiler {
    static let tableModelType:
        UInt32 = 6001

    static let tableDataListType:
        UInt32 = 6005

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeFormulaProfile {
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
    ) throws -> NumbersNativeFormulaProfile {
        var tables:
            [NumbersNativeFormulaProfile.Table] = []

        for tableModel in messages where
            tableModel.type == tableModelType
        {
            let fields =
                try NumbersWire.decode(
                    tableModel.payload,
                    context:
                        "TST.TableModelArchive formula profile"
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
                        "TST.DataStore formula profile"
                )

            guard
                let formulaReferenceField =
                    dataStoreFields.first(
                        where: {
                            $0.number == 6
                            && $0.wireType == 2
                        }
                    )
            else {
                continue
            }

            let formulaReference =
                try reference(
                    formulaReferenceField.bytes,
                    context:
                        "TST.DataStore.formulaTable"
                )

            let formulaTable =
                try store.message(
                    identifier:
                        formulaReference,
                    type:
                        tableDataListType,
                    context:
                        "TST.DataStore \(tableName) formulaTable"
                )

            tables.append(
                NumbersNativeFormulaProfile.Table(
                    tableModelIdentifier:
                        tableModel.identifier,
                    name:
                        tableName,
                    formulaTableReference:
                        formulaReference,
                    formulas:
                        try decodeFormulaTable(
                            formulaTable,
                            tableName:
                                tableName
                        )
                )
            )
        }

        return NumbersNativeFormulaProfile(
            tables:
                tables.sorted {
                    $0.name < $1.name
                }
        )
    }

    private static func decodeFormulaTable(
        _ message: NumbersObjectMessage,
        tableName: String
    ) throws -> [NumbersNativeFormulaProfile.Formula] {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.TableDataList formula table \(tableName)"
            )

        guard
            let listType =
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
                    "TST.TableDataList formula table \(tableName) missing listType"
                )
        }

        guard listType == 3 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.DataStore \(tableName) formulaTable has listType \(listType), expected FORMULA=3"
                )
        }

        return try fields
            .filter {
                $0.number == 3
                && $0.wireType == 2
            }
            .map {
                try decodeFormulaEntry(
                    $0.bytes,
                    tableName:
                        tableName
                )
            }
            .sorted {
                $0.key < $1.key
            }
    }

    private static func decodeFormulaEntry(
        _ bytes: [UInt8],
        tableName: String
    ) throws -> NumbersNativeFormulaProfile.Formula {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TableDataList.ListEntry formula \(tableName)"
            )

        guard
            let keyRaw =
                fields.first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint,
            let key =
                UInt32(
                    exactly:
                        keyRaw
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula ListEntry for \(tableName) missing valid key"
                )
        }

        guard
            let formulaField =
                fields.first(
                    where: {
                        $0.number == 5
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "formula ListEntry \(key) for \(tableName) missing FormulaArchive"
                )
        }

        return try decodeFormulaArchive(
            formulaField.bytes,
            key:
                key,
            tableName:
                tableName
        )
    }

    private static func decodeFormulaArchive(
        _ bytes: [UInt8],
        key: UInt32,
        tableName: String
    ) throws -> NumbersNativeFormulaProfile.Formula {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TSCE.FormulaArchive \(tableName) key \(key)"
            )

        guard
            let astField =
                fields.first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TSCE.FormulaArchive \(tableName) key \(key) missing AST_node_array"
                )
        }

        let astFields =
            try NumbersWire.decode(
                astField.bytes,
                context:
                    "TSCE.ASTNodeArrayArchive \(tableName) key \(key)"
            )

        let nodes =
            try astFields
                .filter {
                    $0.number == 1
                    && $0.wireType == 2
                }
                .map {
                    try decodeNode(
                        $0.bytes,
                        tableName:
                            tableName,
                        formulaKey:
                            key
                    )
                }

        return NumbersNativeFormulaProfile.Formula(
            key:
                key,
            hostColumn:
                optionalVarint(
                    fields,
                    number: 2
                ),
            hostRow:
                optionalVarint(
                    fields,
                    number: 3
                ),
            fieldSignatures:
                signatures(
                    fields
                ),
            nodes:
                nodes
        )
    }

    private static func decodeNode(
        _ bytes: [UInt8],
        tableName: String,
        formulaKey: UInt32
    ) throws -> NumbersNativeFormulaProfile.Node {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TSCE.ASTNodeArchive \(tableName) key \(formulaKey)"
            )

        let numberValue:
            Double?

        if let numberField =
            fields.first(
                where: {
                    $0.number == 4
                    && $0.wireType == 1
                }
            )
        {
            numberValue =
                try littleEndianDouble(
                    numberField.bytes,
                    context:
                        "TSCE.ASTNodeArchive number"
                )
        } else {
            numberValue = nil
        }

        return NumbersNativeFormulaProfile.Node(
            type:
                optionalVarint(
                    fields,
                    number: 1
                ),
            fieldSignatures:
                signatures(
                    fields
                ),
            numberValue:
                numberValue,
            column:
                try optionalCoordinate(
                    fields,
                    number: 26,
                    context:
                        "TSCE.ASTNodeArchive column"
                ),
            row:
                try optionalCoordinate(
                    fields,
                    number: 27,
                    context:
                        "TSCE.ASTNodeArchive row"
                )
        )
    }

    private static func optionalCoordinate(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> NumbersNativeFormulaProfile.Coordinate? {
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

        let coordinateFields =
            try NumbersWire.decode(
                field.bytes,
                context:
                    context
            )

        return NumbersNativeFormulaProfile.Coordinate(
            rawValue:
                optionalVarint(
                    coordinateFields,
                    number: 1
                )
                .map(
                    zigZagDecode
                ),
            absolute:
                optionalVarint(
                    coordinateFields,
                    number: 2
                )
                .map {
                    $0 != 0
                },
            fieldSignatures:
                signatures(
                    coordinateFields
                )
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

        guard
            let identifier =
                optionalVarint(
                    fields,
                    number: 1
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): missing reference identifier"
                )
        }

        return identifier
    }

    private static func optionalVarint(
        _ fields: [NumbersWire.Field],
        number: UInt64
    ) -> UInt64? {
        fields.first(
            where: {
                $0.number == number
                && $0.wireType == 0
            }
        )?
        .varint
    }

    private static func signatures(
        _ fields: [NumbersWire.Field]
    ) -> [String] {
        fields.map {
            "\($0.number)/\($0.wireType)"
        }
    }

    private static func zigZagDecode(
        _ raw: UInt64
    ) -> Int64 {
        Int64(
            bitPattern:
                raw >> 1
        )
        ^ -Int64(
            raw & 1
        )
    }

    private static func littleEndianDouble(
        _ bytes: [UInt8],
        context: String
    ) throws -> Double {
        guard bytes.count == 8 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): fixed64 payload is \(bytes.count) bytes"
                )
        }

        var raw:
            UInt64 = 0

        for index in 0..<8 {
            raw |=
                UInt64(
                    bytes[index]
                )
                << UInt64(
                    index * 8
                )
        }

        return Double(
            bitPattern:
                raw
        )
    }
}
