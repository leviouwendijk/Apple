import Foundation

@_spi(Testing)
public struct NumbersNativeFormatProfile:
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
        public let name: String
        public let formatTableReference: UInt64

        public let nextListID: UInt32?
        public let fieldSignatures: [String]

        public let entries: [Entry]

        public init(
            name: String,
            formatTableReference: UInt64,
            nextListID: UInt32?,
            fieldSignatures: [String],
            entries: [Entry]
        ) {
            self.name = name
            self.formatTableReference = formatTableReference
            self.nextListID = nextListID
            self.fieldSignatures = fieldSignatures
            self.entries = entries
        }
    }

    public struct Entry:
        Sendable
    {
        public let key: UInt32
        public let refcount: UInt32?
        public let fieldSignatures: [String]

        public let formatType: UInt64?
        public let decimalPlaces: UInt64?
        public let currencyCode: String?
        public let negativeStyle: UInt64?
        public let showThousandsSeparator: Bool?
        public let useAccountingStyle: Bool?
        public let durationStyle: UInt64?
        public let base: UInt64?
        public let basePlaces: UInt64?
        public let baseUseMinusSign: Bool?
        public let fractionAccuracy: UInt64?
        public let suppressDateFormat: Bool?
        public let suppressTimeFormat: Bool?
        public let dateTimeFormat: String?
        public let durationUnitLargest: UInt64?
        public let durationUnitSmallest: UInt64?

        public init(
            key: UInt32,
            refcount: UInt32?,
            fieldSignatures: [String],
            formatType: UInt64?,
            decimalPlaces: UInt64?,
            currencyCode: String?,
            negativeStyle: UInt64?,
            showThousandsSeparator: Bool?,
            useAccountingStyle: Bool?,
            durationStyle: UInt64?,
            base: UInt64?,
            basePlaces: UInt64?,
            baseUseMinusSign: Bool?,
            fractionAccuracy: UInt64?,
            suppressDateFormat: Bool?,
            suppressTimeFormat: Bool?,
            dateTimeFormat: String?,
            durationUnitLargest: UInt64?,
            durationUnitSmallest: UInt64?
        ) {
            self.key = key
            self.refcount = refcount
            self.fieldSignatures = fieldSignatures
            self.formatType = formatType
            self.decimalPlaces = decimalPlaces
            self.currencyCode = currencyCode
            self.negativeStyle = negativeStyle
            self.showThousandsSeparator = showThousandsSeparator
            self.useAccountingStyle = useAccountingStyle
            self.durationStyle = durationStyle
            self.base = base
            self.basePlaces = basePlaces
            self.baseUseMinusSign = baseUseMinusSign
            self.fractionAccuracy = fractionAccuracy
            self.suppressDateFormat = suppressDateFormat
            self.suppressTimeFormat = suppressTimeFormat
            self.dateTimeFormat = dateTimeFormat
            self.durationUnitLargest = durationUnitLargest
            self.durationUnitSmallest = durationUnitSmallest
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func formatProfile(
        at documentURL: URL
    ) throws -> NumbersNativeFormatProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeFormatProfiler.decode(
            messages
        )
    }
}

private enum NumbersNativeFormatProfiler {
    static let tableModelType:
        UInt32 = 6001

    static let tableDataListType:
        UInt32 = 6005

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeFormatProfile {
        let store =
            ObjectStore(
                messages
            )

        var tables:
            [NumbersNativeFormatProfile.Table] = []

        for tableModel in messages where
            tableModel.type == tableModelType
        {
            let fields =
                try NumbersWire.decode(
                    tableModel.payload,
                    context:
                        "TST.TableModelArchive format profile"
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
                        "TST.DataStore format profile"
                )

            guard
                let formatReferenceField =
                    dataStoreFields.first(
                        where: {
                            $0.number == 11
                            && $0.wireType == 2
                        }
                    )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.DataStore \(tableName) missing formatTable"
                    )
            }

            let formatReference =
                try reference(
                    formatReferenceField.bytes,
                    context:
                        "TST.DataStore.formatTable"
                )

            let formatTable =
                try store.message(
                    identifier:
                        formatReference,
                    type:
                        tableDataListType,
                    context:
                        "TST.DataStore \(tableName) formatTable"
                )

            let decodedFormatTable =
                try decodeFormatTable(
                    formatTable,
                    tableName:
                        tableName
                )

            tables.append(
                NumbersNativeFormatProfile.Table(
                    name:
                        tableName,
                    formatTableReference:
                        formatReference,
                    nextListID:
                        decodedFormatTable
                            .nextListID,
                    fieldSignatures:
                        decodedFormatTable
                            .fieldSignatures,
                    entries:
                        decodedFormatTable
                            .entries
                )
            )
        }

        return NumbersNativeFormatProfile(
            tables:
                tables.sorted {
                    $0.name < $1.name
                }
        )
    }

    private struct DecodedFormatTable {
        let nextListID: UInt32?
        let fieldSignatures: [String]
        let entries: [NumbersNativeFormatProfile.Entry]
    }

    private static func decodeFormatTable(
        _ message: NumbersObjectMessage,
        tableName: String
    ) throws -> DecodedFormatTable {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.TableDataList format table \(tableName)"
            )

        guard
            let listType =
                optionalVarint(
                    fields,
                    number: 1
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableDataList format table \(tableName) missing listType"
                )
        }

        guard listType == 2 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.DataStore \(tableName) formatTable has listType \(listType), expected FORMAT=2"
                )
        }

        let nextListID:
            UInt32?

        if let raw =
            optionalVarint(
                fields,
                number: 2
            )
        {
            guard let value =
                UInt32(
                    exactly:
                        raw
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "TST.TableDataList format table \(tableName) nextListID is outside UInt32"
                    )
            }

            nextListID =
                value
        } else {
            nextListID =
                nil
        }

        let entries =
            try fields
                .filter {
                    $0.number == 3
                    && $0.wireType == 2
                }
                .map {
                    try decodeFormatEntry(
                        $0.bytes,
                        tableName:
                            tableName
                    )
                }
                .sorted {
                    $0.key < $1.key
                }

        return DecodedFormatTable(
            nextListID:
                nextListID,
            fieldSignatures:
                signatures(
                    fields
                ),
            entries:
                entries
        )
    }

    private static func decodeFormatEntry(
        _ bytes: [UInt8],
        tableName: String
    ) throws -> NumbersNativeFormatProfile.Entry {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TableDataList.ListEntry format \(tableName)"
            )

        guard
            let keyRaw =
                optionalVarint(
                    fields,
                    number: 1
                ),
            let key =
                UInt32(
                    exactly:
                        keyRaw
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "format ListEntry for \(tableName) missing valid key"
                )
        }

        let refcount:
            UInt32?

        if let raw =
            optionalVarint(
                fields,
                number: 2
            )
        {
            guard let value =
                UInt32(
                    exactly:
                        raw
                )
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "format ListEntry \(key) for \(tableName) has refcount outside UInt32"
                    )
            }

            refcount = value
        } else {
            refcount = nil
        }

        guard
            let formatField =
                fields.first(
                    where: {
                        $0.number == 6
                        && $0.wireType == 2
                    }
                )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "format ListEntry \(key) for \(tableName) missing FormatStructArchive"
                )
        }

        return try decodeFormatArchive(
            formatField.bytes,
            key:
                key,
            refcount:
                refcount,
            tableName:
                tableName
        )
    }

    private static func decodeFormatArchive(
        _ bytes: [UInt8],
        key: UInt32,
        refcount: UInt32?,
        tableName: String
    ) throws -> NumbersNativeFormatProfile.Entry {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TSK.FormatStructArchive \(tableName) key \(key)"
            )

        return NumbersNativeFormatProfile.Entry(
            key:
                key,
            refcount:
                refcount,
            fieldSignatures:
                signatures(
                    fields
                ),
            formatType:
                optionalVarint(
                    fields,
                    number: 1
                ),
            decimalPlaces:
                optionalVarint(
                    fields,
                    number: 2
                ),
            currencyCode:
                try optionalString(
                    fields,
                    number: 3,
                    context:
                        "TSK.FormatStructArchive.currency_code"
                ),
            negativeStyle:
                optionalVarint(
                    fields,
                    number: 4
                ),
            showThousandsSeparator:
                optionalBool(
                    fields,
                    number: 5
                ),
            useAccountingStyle:
                optionalBool(
                    fields,
                    number: 6
                ),
            durationStyle:
                optionalVarint(
                    fields,
                    number: 7
                ),
            base:
                optionalVarint(
                    fields,
                    number: 8
                ),
            basePlaces:
                optionalVarint(
                    fields,
                    number: 9
                ),
            baseUseMinusSign:
                optionalBool(
                    fields,
                    number: 10
                ),
            fractionAccuracy:
                optionalVarint(
                    fields,
                    number: 11
                ),
            suppressDateFormat:
                optionalBool(
                    fields,
                    number: 12
                ),
            suppressTimeFormat:
                optionalBool(
                    fields,
                    number: 13
                ),
            dateTimeFormat:
                try optionalString(
                    fields,
                    number: 14,
                    context:
                        "TSK.FormatStructArchive.date_time_format"
                ),
            durationUnitLargest:
                optionalVarint(
                    fields,
                    number: 15
                ),
            durationUnitSmallest:
                optionalVarint(
                    fields,
                    number: 16
                )
        )
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

    private static func optionalBool(
        _ fields: [NumbersWire.Field],
        number: UInt64
    ) -> Bool? {
        optionalVarint(
            fields,
            number:
                number
        )
        .map {
            $0 != 0
        }
    }

    private static func optionalString(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> String? {
        guard let field =
            fields.first(
                where: {
                    $0.number == number
                    && $0.wireType == 2
                }
            )
        else {
            return nil
        }

        guard let value =
            String(
                bytes:
                    field.bytes,
                encoding:
                    .utf8
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): invalid UTF-8"
                )
        }

        return value
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

    private static func signatures(
        _ fields: [NumbersWire.Field]
    ) -> [String] {
        fields.map {
            "\($0.number)/\($0.wireType)"
        }
    }

    private struct ObjectStore {
        let values:
            [UInt64: [NumbersObjectMessage]]

        init(
            _ messages: [NumbersObjectMessage]
        ) {
            values =
                Dictionary(
                    grouping:
                        messages,
                    by:
                        \.identifier
                )
        }

        func message(
            identifier: UInt64,
            type: UInt32,
            context: String
        ) throws -> NumbersObjectMessage {
            let matches =
                values[
                    identifier
                ]?
                .filter {
                    $0.type == type
                }
                ?? []

            guard matches.count == 1 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): expected one object \(identifier) of type \(type), found \(matches.count)"
                    )
            }

            return matches[0]
        }
    }
}
