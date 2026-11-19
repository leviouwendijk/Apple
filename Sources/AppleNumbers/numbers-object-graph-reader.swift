import Foundation
import ZIPFoundation

@_spi(Testing)
public struct NumbersNativeDocumentStructure:
    Equatable,
    Sendable
{
    public let sheets: [Sheet]

    public init(
        sheets: [Sheet]
    ) {
        self.sheets = sheets
    }

    public struct Sheet:
        Equatable,
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
            self.identifier = identifier
            self.name = name
            self.tables = tables
        }
    }

    public struct Table:
        Equatable,
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

        public init(
            tableInfoIdentifier: UInt64,
            tableModelIdentifier: UInt64,
            name: String,
            rowCount: Int,
            columnCount: Int,
            headerRowCount: Int,
            headerColumnCount: Int,
            footerRowCount: Int
        ) {
            self.tableInfoIdentifier = tableInfoIdentifier
            self.tableModelIdentifier = tableModelIdentifier
            self.name = name
            self.rowCount = rowCount
            self.columnCount = columnCount
            self.headerRowCount = headerRowCount
            self.headerColumnCount = headerColumnCount
            self.footerRowCount = footerRowCount
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func structure(
        at documentURL: URL
    ) throws -> NumbersNativeDocumentStructure {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeStructureDecoder.decode(
            messages
        )
    }
}

struct NumbersObjectMessage:
    Sendable
{
    let identifier: UInt64
    let type: UInt32
    let payload: [UInt8]
}

struct NumbersObjectStore:
    Sendable
{
    let messages:
        [UInt64: [NumbersObjectMessage]]

    init(
        _ values: [NumbersObjectMessage]
    ) {
        messages =
            Dictionary(
                grouping:
                    values,
                by:
                    \.identifier
            )
    }

    func contains(
        identifier: UInt64,
        type: UInt32
    ) -> Bool {
        messages[
            identifier
        ]?
        .contains {
            $0.type == type
        }
        ?? false
    }

    func message(
        identifier: UInt64,
        type: UInt32,
        context: String
    ) throws -> NumbersObjectMessage {
        let matches =
            messages[
                identifier
            ]?
            .filter {
                $0.type == type
            }
            ?? []

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): reference \(identifier) expected one message of type \(type), found \(matches.count)"
                )
        }

        return matches[0]
    }
}

enum NumbersObjectArchiveReader {
    static func read(
        at documentURL: URL
    ) throws -> [NumbersObjectMessage] {
        var isDirectory =
            ObjCBool(
                false
            )

        guard FileManager.default.fileExists(
            atPath: documentURL.path,
            isDirectory: &isDirectory
        ) else {
            throw NumbersObjectGraphError.invalidDocument(
                "document does not exist: \(documentURL.path)"
            )
        }

        var messages: [NumbersObjectMessage] = []

        if isDirectory.boolValue {
            let indexURL =
                documentURL.appendingPathComponent(
                    "Index.zip"
                )

            guard FileManager.default.fileExists(
                atPath: indexURL.path
            ) else {
                throw NumbersObjectGraphError.invalidDocument(
                    "expanded Numbers package is missing Index.zip"
                )
            }

            let archive =
                try Archive(
                    url: indexURL,
                    accessMode: .read
                )

            try collect(
                archive,
                prefix: "",
                messages: &messages
            )
        } else {
            let archive =
                try Archive(
                    url: documentURL,
                    accessMode: .read
                )

            try collect(
                archive,
                prefix: "",
                messages: &messages
            )
        }

        return messages
    }

    private static func collect(
        _ archive: Archive,
        prefix: String,
        messages: inout [NumbersObjectMessage]
    ) throws {
        for entry in archive {
            let normalized =
                entry.path
                    .lowercased()

            if normalized.hasSuffix(
                "index.zip"
            ) {
                let bytes =
                    try data(
                        from: archive,
                        entry: entry
                    )

                let nested =
                    try Archive(
                        data: bytes,
                        accessMode: .read
                    )

                try collect(
                    nested,
                    prefix:
                        prefix
                        + entry.path
                        + "::",
                    messages:
                        &messages
                )

                continue
            }

            guard normalized.hasSuffix(
                ".iwa"
            ) else {
                continue
            }

            let bytes =
                try data(
                    from: archive,
                    entry: entry
                )

            messages.append(
                contentsOf:
                    try decodeIWA(
                        bytes,
                        source:
                            prefix
                            + entry.path
                    )
            )
        }
    }

    private static func data(
        from archive: Archive,
        entry: Entry
    ) throws -> Data {
        var result =
            Data()

        _ = try archive.extract(
            entry,
            consumer: {
                result.append(
                    $0
                )
            }
        )

        return result
    }

    private static func decodeIWA(
        _ data: Data,
        source: String
    ) throws -> [NumbersObjectMessage] {
        let bytes =
            Array(
                data
            )

        if NumbersLZFSE.isSupportedStream(
            bytes
        ) {
            let protobuf =
                try NumbersLZFSE.decompress(
                    bytes,
                    source:
                        source
                )

            return try decodeArchiveStream(
                protobuf,
                source:
                    source
            )
        }

        var offset = 0
        var protobuf: [UInt8] = []

        while offset < bytes.count {
            guard
                offset + 4
                    <= bytes.count
            else {
                throw NumbersObjectGraphError.invalidIWA(
                    "\(source): truncated IWA frame header"
                )
            }

            let frameType =
                bytes[
                    offset
                ]

            let frameLength =
                Int(
                    bytes[
                        offset + 1
                    ]
                )
                | (
                    Int(
                        bytes[
                            offset + 2
                        ]
                    )
                    << 8
                )
                | (
                    Int(
                        bytes[
                            offset + 3
                        ]
                    )
                    << 16
                )

            offset += 4

            guard frameType == 0 else {
                throw NumbersObjectGraphError.invalidIWA(
                    "\(source): unsupported IWA frame type \(frameType)"
                )
            }

            guard
                frameLength > 0,
                offset + frameLength
                    <= bytes.count
            else {
                throw NumbersObjectGraphError.invalidIWA(
                    "\(source): invalid IWA frame length \(frameLength)"
                )
            }

            let compressed =
                Array(
                    bytes[
                        offset
                        ..<
                        offset + frameLength
                    ]
                )

            offset +=
                frameLength

            protobuf.append(
                contentsOf:
                    try NumbersSnappy.decompress(
                        compressed
                    )
            )
        }

        return try decodeArchiveStream(
            protobuf,
            source: source
        )
    }

    private static func decodeArchiveStream(
        _ bytes: [UInt8],
        source: String
    ) throws -> [NumbersObjectMessage] {
        var offset = 0
        var result: [NumbersObjectMessage] = []

        while offset < bytes.count {
            let infoLengthRaw =
                try readVarint(
                    bytes,
                    offset: &offset,
                    context:
                        "\(source) ArchiveInfo length"
                )

            guard let infoLength =
                Int(
                    exactly:
                        infoLengthRaw
                )
            else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(source): ArchiveInfo length does not fit Int"
                )
            }

            guard
                infoLength >= 0,
                offset + infoLength
                    <= bytes.count
            else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(source): ArchiveInfo exceeds IWA stream"
                )
            }

            let info =
                Array(
                    bytes[
                        offset
                        ..<
                        offset + infoLength
                    ]
                )

            offset +=
                infoLength

            let archiveInfo =
                try decodeArchiveInfo(
                    info,
                    source: source
                )

            guard let identifier =
                archiveInfo.identifier
            else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(source): ArchiveInfo has no identifier"
                )
            }

            for message in archiveInfo.messages {
                guard
                    message.length >= 0,
                    offset + message.length
                        <= bytes.count
                else {
                    throw NumbersObjectGraphError.invalidProtobuf(
                        "\(source): message payload exceeds IWA stream"
                    )
                }

                let payload =
                    Array(
                        bytes[
                            offset
                            ..<
                            offset + message.length
                        ]
                    )

                offset +=
                    message.length

                result.append(
                    NumbersObjectMessage(
                        identifier:
                            identifier,
                        type:
                            message.type,
                        payload:
                            payload
                    )
                )
            }
        }

        return result
    }

    private struct ArchiveInfo {
        let identifier: UInt64?
        let messages: [MessageInfo]
    }

    private struct MessageInfo {
        let type: UInt32
        let length: Int
    }

    private static func decodeArchiveInfo(
        _ bytes: [UInt8],
        source: String
    ) throws -> ArchiveInfo {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "\(source) ArchiveInfo"
            )

        let identifier =
            fields
                .first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint

        let messages =
            try fields
                .filter {
                    $0.number == 2
                    && $0.wireType == 2
                }
                .map {
                    try decodeMessageInfo(
                        $0.bytes,
                        source: source
                    )
                }

        guard !messages.isEmpty else {
            throw NumbersObjectGraphError.invalidProtobuf(
                "\(source): ArchiveInfo contains no MessageInfo"
            )
        }

        return ArchiveInfo(
            identifier: identifier,
            messages: messages
        )
    }

    private static func decodeMessageInfo(
        _ bytes: [UInt8],
        source: String
    ) throws -> MessageInfo {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "\(source) MessageInfo"
            )

        guard
            let typeRaw =
                fields.first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint,
            let type =
                UInt32(
                    exactly:
                        typeRaw
                )
        else {
            throw NumbersObjectGraphError.invalidProtobuf(
                "\(source): MessageInfo missing valid type"
            )
        }

        guard
            let lengthRaw =
                fields.first(
                    where: {
                        $0.number == 3
                        && $0.wireType == 0
                    }
                )?
                .varint,
            let length =
                Int(
                    exactly:
                        lengthRaw
                )
        else {
            throw NumbersObjectGraphError.invalidProtobuf(
                "\(source): MessageInfo missing valid length"
            )
        }

        return MessageInfo(
            type: type,
            length: length
        )
    }

    private static func readVarint(
        _ bytes: [UInt8],
        offset: inout Int,
        context: String
    ) throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0

        while true {
            guard offset < bytes.count else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): truncated varint"
                )
            }

            let byte =
                bytes[
                    offset
                ]

            offset += 1

            guard shift < 64 else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): varint exceeds UInt64"
                )
            }

            result |=
                UInt64(
                    byte
                    & 0x7F
                )
                << shift

            if byte & 0x80 == 0 {
                return result
            }

            shift += 7
        }
    }
}

enum NumbersNativeStructureDecoder {
    static let documentType:
        UInt32 = 1

    static let sheetType:
        UInt32 = 2

    static let tableInfoType:
        UInt32 = 6000

    static let tableModelType:
        UInt32 = 6001

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeDocumentStructure {
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
    ) throws -> NumbersNativeDocumentStructure {
        let documentMessages =
            messages.filter {
                $0.type == documentType
            }

        guard documentMessages.count == 1 else {
            throw NumbersObjectGraphError.invalidObjectGraph(
                "expected exactly one TN.DocumentArchive, found \(documentMessages.count)"
            )
        }

        let document =
            documentMessages[0]

        let documentFields =
            try NumbersWire.decode(
                document.payload,
                context:
                    "TN.DocumentArchive"
            )

        let sheetReferences =
            try references(
                from:
                    documentFields.filter {
                        $0.number == 1
                        && $0.wireType == 2
                    },
                context:
                    "TN.DocumentArchive.sheets"
            )

        var sheets:
            [NumbersNativeDocumentStructure.Sheet] = []

        for sheetReference in sheetReferences {
            let sheetMessage =
                try store.message(
                    identifier:
                        sheetReference,
                    type:
                        sheetType,
                    context:
                        "TN.DocumentArchive.sheets"
                )

            sheets.append(
                try decodeSheet(
                    sheetMessage,
                    store: store
                )
            )
        }

        return NumbersNativeDocumentStructure(
            sheets: sheets
        )
    }

    private static func decodeSheet(
        _ message: NumbersObjectMessage,
        store: NumbersObjectStore
    ) throws -> NumbersNativeDocumentStructure.Sheet {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TN.SheetArchive"
            )

        let name =
            try requiredString(
                fields,
                number: 1,
                context:
                    "TN.SheetArchive.name"
            )

        let drawableReferences =
            try references(
                from:
                    fields.filter {
                        $0.number == 2
                        && $0.wireType == 2
                    },
                context:
                    "TN.SheetArchive.drawable_infos"
            )

        var tables:
            [NumbersNativeDocumentStructure.Table] = []

        for drawableReference in drawableReferences {
            guard store.contains(
                identifier:
                    drawableReference,
                type:
                    tableInfoType
            ) else {
                continue
            }

            let tableInfo =
                try store.message(
                    identifier:
                        drawableReference,
                    type:
                        tableInfoType,
                    context:
                        "TN.SheetArchive.drawable_infos"
                )

            tables.append(
                try decodeTable(
                    tableInfo,
                    store: store
                )
            )
        }

        return NumbersNativeDocumentStructure.Sheet(
            identifier: message.identifier,
            name: name,
            tables: tables
        )
    }

    private static func decodeTable(
        _ tableInfo: NumbersObjectMessage,
        store: NumbersObjectStore
    ) throws -> NumbersNativeDocumentStructure.Table {
        let tableInfoFields =
            try NumbersWire.decode(
                tableInfo.payload,
                context:
                    "TST.TableInfoArchive"
            )

        guard
            let tableModelField =
                tableInfoFields.first(
                    where: {
                        $0.number == 2
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError.invalidObjectGraph(
                "TST.TableInfoArchive missing tableModel reference"
            )
        }

        let tableModelReference =
            try reference(
                tableModelField.bytes,
                context:
                    "TST.TableInfoArchive.tableModel"
            )

        let tableModel =
            try store.message(
                identifier:
                    tableModelReference,
                type:
                    tableModelType,
                context:
                    "TST.TableInfoArchive.tableModel"
            )

        let fields =
            try NumbersWire.decode(
                tableModel.payload,
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

        let rowCount =
            try requiredInt(
                fields,
                number: 6,
                context:
                    "TST.TableModelArchive.number_of_rows"
            )

        let columnCount =
            try requiredInt(
                fields,
                number: 7,
                context:
                    "TST.TableModelArchive.number_of_columns"
            )

        let headerRows =
            try optionalInt(
                fields,
                number: 9,
                default: 0,
                context:
                    "TST.TableModelArchive.number_of_header_rows"
            )

        let headerColumns =
            try optionalInt(
                fields,
                number: 10,
                default: 0,
                context:
                    "TST.TableModelArchive.number_of_header_columns"
            )

        let footerRows =
            try optionalInt(
                fields,
                number: 11,
                default: 0,
                context:
                    "TST.TableModelArchive.number_of_footer_rows"
            )

        return NumbersNativeDocumentStructure.Table(
            tableInfoIdentifier: tableInfo.identifier,
            tableModelIdentifier: tableModel.identifier,
            name: name,
            rowCount: rowCount,
            columnCount: columnCount,
            headerRowCount: headerRows,
            headerColumnCount: headerColumns,
            footerRowCount: footerRows
        )
    }

    private static func references(
        from fields: [NumbersWire.Field],
        context: String
    ) throws -> [UInt64] {
        try fields.map {
            try reference(
                $0.bytes,
                context: context
            )
        }
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
            throw NumbersObjectGraphError.invalidObjectGraph(
                "\(context): TSP.Reference missing identifier"
            )
        }

        return identifier
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
            let result =
                String(
                    bytes: field.bytes,
                    encoding: .utf8
                )
        else {
            throw NumbersObjectGraphError.invalidObjectGraph(
                "\(context): missing or invalid UTF-8 string"
            )
        }

        return result
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
            let result =
                Int(
                    exactly:
                        raw
                )
        else {
            throw NumbersObjectGraphError.invalidObjectGraph(
                "\(context): missing or invalid integer"
            )
        }

        return result
    }

    private static func optionalInt(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        default defaultValue: Int,
        context: String
    ) throws -> Int {
        guard
            let field =
                fields.first(
                    where: {
                        $0.number == number
                        && $0.wireType == 0
                    }
                )
        else {
            return defaultValue
        }

        guard
            let raw =
                field.varint,
            let result =
                Int(
                    exactly:
                        raw
                )
        else {
            throw NumbersObjectGraphError.invalidObjectGraph(
                "\(context): invalid integer"
            )
        }

        return result
    }
}

enum NumbersWire {
    struct Field {
        let number: UInt64
        let wireType: UInt64

        let varint: UInt64?
        let bytes: [UInt8]
    }

    static func decode(
        _ bytes: [UInt8],
        context: String
    ) throws -> [Field] {
        var offset = 0
        var result: [Field] = []

        while offset < bytes.count {
            let key =
                try readVarint(
                    bytes,
                    offset: &offset,
                    context:
                        "\(context) field key"
                )

            let number =
                key >> 3

            let wireType =
                key & 0x07

            guard number > 0 else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): protobuf field number zero"
                )
            }

            switch wireType {
            case 0:
                let value =
                    try readVarint(
                        bytes,
                        offset: &offset,
                        context:
                            "\(context) field \(number)"
                    )

                result.append(
                    Field(
                        number: number,
                        wireType: wireType,
                        varint: value,
                        bytes: []
                    )
                )

            case 1:
                guard
                    offset + 8
                        <= bytes.count
                else {
                    throw NumbersObjectGraphError.invalidProtobuf(
                        "\(context): truncated fixed64 field \(number)"
                    )
                }

                result.append(
                    Field(
                        number: number,
                        wireType: wireType,
                        varint: nil,
                        bytes:
                            Array(
                                bytes[
                                    offset
                                    ..<
                                    offset + 8
                                ]
                            )
                    )
                )

                offset += 8

            case 2:
                let lengthRaw =
                    try readVarint(
                        bytes,
                        offset: &offset,
                        context:
                            "\(context) field \(number) length"
                    )

                guard
                    let length =
                        Int(
                            exactly:
                                lengthRaw
                        ),
                    length >= 0,
                    offset + length
                        <= bytes.count
                else {
                    throw NumbersObjectGraphError.invalidProtobuf(
                        "\(context): invalid length-delimited field \(number)"
                    )
                }

                result.append(
                    Field(
                        number: number,
                        wireType: wireType,
                        varint: nil,
                        bytes:
                            Array(
                                bytes[
                                    offset
                                    ..<
                                    offset + length
                                ]
                            )
                    )
                )

                offset +=
                    length

            case 5:
                guard
                    offset + 4
                        <= bytes.count
                else {
                    throw NumbersObjectGraphError.invalidProtobuf(
                        "\(context): truncated fixed32 field \(number)"
                    )
                }

                result.append(
                    Field(
                        number: number,
                        wireType: wireType,
                        varint: nil,
                        bytes:
                            Array(
                                bytes[
                                    offset
                                    ..<
                                    offset + 4
                                ]
                            )
                    )
                )

                offset += 4

            default:
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): unsupported protobuf wire type \(wireType)"
                )
            }
        }

        return result
    }

    private static func readVarint(
        _ bytes: [UInt8],
        offset: inout Int,
        context: String
    ) throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0

        while true {
            guard offset < bytes.count else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): truncated varint"
                )
            }

            let byte =
                bytes[
                    offset
                ]

            offset += 1

            guard shift < 64 else {
                throw NumbersObjectGraphError.invalidProtobuf(
                    "\(context): varint exceeds UInt64"
                )
            }

            result |=
                UInt64(
                    byte
                    & 0x7F
                )
                << shift

            if byte & 0x80 == 0 {
                return result
            }

            shift += 7
        }
    }
}

enum NumbersObjectGraphError:
    Error,
    CustomStringConvertible
{
    case invalidDocument(String)
    case invalidIWA(String)
    case invalidProtobuf(String)
    case invalidObjectGraph(String)

    var description: String {
        switch self {
        case .invalidDocument(
            let message
        ):
            return "Invalid Numbers document: \(message)"

        case .invalidIWA(
            let message
        ):
            return "Invalid Numbers IWA stream: \(message)"

        case .invalidProtobuf(
            let message
        ):
            return "Invalid Numbers protobuf: \(message)"

        case .invalidObjectGraph(
            let message
        ):
            return "Invalid Numbers object graph: \(message)"
        }
    }
}
