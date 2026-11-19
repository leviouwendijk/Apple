import Foundation

@_spi(Testing)
public struct NumbersNativeModernDataListProfile:
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
        public let tableModelIdentifier: UInt64

        public let controlCellSpecTable: DataList?
        public let formatTable: DataList?

        public init(
            name: String,
            tableModelIdentifier: UInt64,
            controlCellSpecTable: DataList?,
            formatTable: DataList?
        ) {
            self.name = name

            self.tableModelIdentifier =
                tableModelIdentifier

            self.controlCellSpecTable =
                controlCellSpecTable

            self.formatTable =
                formatTable
        }
    }

    public struct DataList:
        Sendable
    {
        public let dataStoreFieldNumber: UInt64
        public let referenceIdentifier: UInt64

        public let listType: UInt64
        public let nextListID: UInt32?

        public let isNewForBNC: Bool?

        public let fieldSignatures: [String]
        public let segmentReferences: [UInt64]

        public let entries: [Entry]

        public init(
            dataStoreFieldNumber: UInt64,
            referenceIdentifier: UInt64,
            listType: UInt64,
            nextListID: UInt32?,
            isNewForBNC: Bool?,
            fieldSignatures: [String],
            segmentReferences: [UInt64],
            entries: [Entry]
        ) {
            self.dataStoreFieldNumber =
                dataStoreFieldNumber

            self.referenceIdentifier =
                referenceIdentifier

            self.listType =
                listType

            self.nextListID =
                nextListID

            self.isNewForBNC =
                isNewForBNC

            self.fieldSignatures =
                fieldSignatures

            self.segmentReferences =
                segmentReferences

            self.entries =
                entries
        }
    }

    public struct Entry:
        Sendable
    {
        public let key: UInt32
        public let refcount: UInt32?

        public let fieldSignatures: [String]

        public let formatArchive: FormatArchive?
        public let cellSpecArchive: CellSpecArchive?

        public init(
            key: UInt32,
            refcount: UInt32?,
            fieldSignatures: [String],
            formatArchive: FormatArchive?,
            cellSpecArchive: CellSpecArchive?
        ) {
            self.key = key
            self.refcount = refcount

            self.fieldSignatures =
                fieldSignatures

            self.formatArchive =
                formatArchive

            self.cellSpecArchive =
                cellSpecArchive
        }
    }

    public struct FormatArchive:
        Sendable
    {
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

        public let scaleFactor: Double?

        public let controlMinimum: Double?
        public let controlMaximum: Double?
        public let controlIncrement: Double?
        public let controlFormatType: UInt64?

        public let decimalWidth: UInt64?
        public let minIntegerWidth: UInt64?

        public let useAutomaticDurationUnits: Bool?

        public init(
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
            durationUnitSmallest: UInt64?,
            scaleFactor: Double?,
            controlMinimum: Double?,
            controlMaximum: Double?,
            controlIncrement: Double?,
            controlFormatType: UInt64?,
            decimalWidth: UInt64?,
            minIntegerWidth: UInt64?,
            useAutomaticDurationUnits: Bool?
        ) {
            self.fieldSignatures =
                fieldSignatures

            self.formatType =
                formatType

            self.decimalPlaces =
                decimalPlaces

            self.currencyCode =
                currencyCode

            self.negativeStyle =
                negativeStyle

            self.showThousandsSeparator =
                showThousandsSeparator

            self.useAccountingStyle =
                useAccountingStyle

            self.durationStyle =
                durationStyle

            self.base =
                base

            self.basePlaces =
                basePlaces

            self.baseUseMinusSign =
                baseUseMinusSign

            self.fractionAccuracy =
                fractionAccuracy

            self.suppressDateFormat =
                suppressDateFormat

            self.suppressTimeFormat =
                suppressTimeFormat

            self.dateTimeFormat =
                dateTimeFormat

            self.durationUnitLargest =
                durationUnitLargest

            self.durationUnitSmallest =
                durationUnitSmallest

            self.scaleFactor =
                scaleFactor

            self.controlMinimum =
                controlMinimum

            self.controlMaximum =
                controlMaximum

            self.controlIncrement =
                controlIncrement

            self.controlFormatType =
                controlFormatType

            self.decimalWidth =
                decimalWidth

            self.minIntegerWidth =
                minIntegerWidth

            self.useAutomaticDurationUnits =
                useAutomaticDurationUnits
        }
    }

    public struct CellSpecArchive:
        Sendable
    {
        public let fieldSignatures: [String]

        public let interactionType: UInt64?

        public let rangeControlMinimum: Double?
        public let rangeControlMaximum: Double?
        public let rangeControlIncrement: Double?

        public let chooserPopupReference: UInt64?
        public let chooserStartsWithFirst: Bool?

        public init(
            fieldSignatures: [String],
            interactionType: UInt64?,
            rangeControlMinimum: Double?,
            rangeControlMaximum: Double?,
            rangeControlIncrement: Double?,
            chooserPopupReference: UInt64?,
            chooserStartsWithFirst: Bool?
        ) {
            self.fieldSignatures =
                fieldSignatures

            self.interactionType =
                interactionType

            self.rangeControlMinimum =
                rangeControlMinimum

            self.rangeControlMaximum =
                rangeControlMaximum

            self.rangeControlIncrement =
                rangeControlIncrement

            self.chooserPopupReference =
                chooserPopupReference

            self.chooserStartsWithFirst =
                chooserStartsWithFirst
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func modernDataListProfile(
        at documentURL: URL
    ) throws -> NumbersNativeModernDataListProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeModernDataListProfiler.decode(
            messages
        )
    }
}

enum NumbersNativeModernDataListProfiler {
    static let tableModelType:
        UInt32 = 6001

    static let tableDataListType:
        UInt32 = 6005

    static let controlCellSpecField:
        UInt64 = 21

    static let formatField:
        UInt64 = 22

    static let controlCellSpecListType:
        UInt64 = 12

    static let formatListType:
        UInt64 = 2

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeModernDataListProfile {
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
    ) throws -> NumbersNativeModernDataListProfile {
        var tables:
            [NumbersNativeModernDataListProfile.Table] = []

        for tableModel in messages where
            tableModel.type == tableModelType
        {
            let tableFields =
                try NumbersWire.decode(
                    tableModel.payload,
                    context:
                        "TST.TableModelArchive modern DataList profile"
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
                        "TST.DataStore \(tableName) modern DataList profile"
                )

            let controlCellSpecTable =
                try optionalDataList(
                    dataStoreFields,
                    fieldNumber:
                        controlCellSpecField,
                    expectedListType:
                        controlCellSpecListType,
                    tableName:
                        tableName,
                    store:
                        store
                )

            let formatTable =
                try optionalDataList(
                    dataStoreFields,
                    fieldNumber:
                        formatField,
                    expectedListType:
                        formatListType,
                    tableName:
                        tableName,
                    store:
                        store
                )

            tables.append(
                NumbersNativeModernDataListProfile.Table(
                    name:
                        tableName,
                    tableModelIdentifier:
                        tableModel.identifier,
                    controlCellSpecTable:
                        controlCellSpecTable,
                    formatTable:
                        formatTable
                )
            )
        }

        return NumbersNativeModernDataListProfile(
            tables:
                tables.sorted {
                    if $0.name != $1.name {
                        return $0.name < $1.name
                    }

                    return $0.tableModelIdentifier
                        < $1.tableModelIdentifier
                }
        )
    }

    private static func optionalDataList(
        _ dataStoreFields: [NumbersWire.Field],
        fieldNumber: UInt64,
        expectedListType: UInt64,
        tableName: String,
        store: NumbersObjectStore
    ) throws -> NumbersNativeModernDataListProfile.DataList? {
        guard let referenceField =
            dataStoreFields.first(
                where: {
                    $0.number == fieldNumber
                    && $0.wireType == 2
                }
            )
        else {
            return nil
        }

        let referenceIdentifier =
            try reference(
                referenceField.bytes,
                context:
                    "TST.DataStore \(tableName) field \(fieldNumber)"
            )

        let message =
            try store.message(
                identifier:
                    referenceIdentifier,
                type:
                    tableDataListType,
                context:
                    "TST.DataStore \(tableName) field \(fieldNumber)"
            )

        return try decodeDataList(
            message,
            fieldNumber:
                fieldNumber,
            expectedListType:
                expectedListType,
            tableName:
                tableName
        )
    }

    private static func decodeDataList(
        _ message: NumbersObjectMessage,
        fieldNumber: UInt64,
        expectedListType: UInt64,
        tableName: String
    ) throws -> NumbersNativeModernDataListProfile.DataList {
        let fields =
            try NumbersWire.decode(
                message.payload,
                context:
                    "TST.TableDataList \(tableName) field \(fieldNumber)"
            )

        guard let listType =
            optionalVarint(
                fields,
                number: 1
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableDataList \(tableName) field \(fieldNumber) missing listType"
                )
        }

        guard listType == expectedListType else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "TST.TableDataList \(tableName) field \(fieldNumber) has listType \(listType), expected \(expectedListType)"
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
                        "TST.TableDataList \(tableName) field \(fieldNumber) nextListID is outside UInt32"
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
                    try decodeEntry(
                        $0.bytes,
                        tableName:
                            tableName,
                        dataStoreFieldNumber:
                            fieldNumber
                    )
                }
                .sorted {
                    $0.key < $1.key
                }

        let segmentReferences =
            try fields
                .filter {
                    $0.number == 4
                    && $0.wireType == 2
                }
                .map {
                    try reference(
                        $0.bytes,
                        context:
                            "TST.TableDataList \(tableName) field \(fieldNumber) segment"
                    )
                }

        return NumbersNativeModernDataListProfile.DataList(
            dataStoreFieldNumber:
                fieldNumber,
            referenceIdentifier:
                message.identifier,
            listType:
                listType,
            nextListID:
                nextListID,
            isNewForBNC:
                optionalBool(
                    fields,
                    number: 5
                ),
            fieldSignatures:
                signatures(
                    fields
                ),
            segmentReferences:
                segmentReferences,
            entries:
                entries
        )
    }

    private static func decodeEntry(
        _ bytes: [UInt8],
        tableName: String,
        dataStoreFieldNumber: UInt64
    ) throws -> NumbersNativeModernDataListProfile.Entry {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.TableDataList.ListEntry \(tableName) field \(dataStoreFieldNumber)"
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
                    "TST.TableDataList.ListEntry \(tableName) field \(dataStoreFieldNumber) missing valid key"
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
                        "TST.TableDataList.ListEntry \(tableName) field \(dataStoreFieldNumber) key \(key) refcount outside UInt32"
                    )
            }

            refcount =
                value
        } else {
            refcount =
                nil
        }

        let formatArchive:
            NumbersNativeModernDataListProfile.FormatArchive?

        if let field =
            fields.first(
                where: {
                    $0.number == 6
                    && $0.wireType == 2
                }
            )
        {
            formatArchive =
                try decodeFormatArchive(
                    field.bytes,
                    tableName:
                        tableName,
                    key:
                        key
                )
        } else {
            formatArchive =
                nil
        }

        let cellSpecArchive:
            NumbersNativeModernDataListProfile.CellSpecArchive?

        if let field =
            fields.first(
                where: {
                    $0.number == 12
                    && $0.wireType == 2
                }
            )
        {
            cellSpecArchive =
                try decodeCellSpecArchive(
                    field.bytes,
                    tableName:
                        tableName,
                    key:
                        key
                )
        } else {
            cellSpecArchive =
                nil
        }

        return NumbersNativeModernDataListProfile.Entry(
            key:
                key,
            refcount:
                refcount,
            fieldSignatures:
                signatures(
                    fields
                ),
            formatArchive:
                formatArchive,
            cellSpecArchive:
                cellSpecArchive
        )
    }

    private static func decodeFormatArchive(
        _ bytes: [UInt8],
        tableName: String,
        key: UInt32
    ) throws -> NumbersNativeModernDataListProfile.FormatArchive {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TSK.FormatStructArchive \(tableName) modern key \(key)"
            )

        return NumbersNativeModernDataListProfile.FormatArchive(
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
                ),
            scaleFactor:
                try optionalDouble(
                    fields,
                    number: 19,
                    context:
                        "TSK.FormatStructArchive.scale_factor"
                ),
            controlMinimum:
                try optionalDouble(
                    fields,
                    number: 21,
                    context:
                        "TSK.FormatStructArchive.control_minimum"
                ),
            controlMaximum:
                try optionalDouble(
                    fields,
                    number: 22,
                    context:
                        "TSK.FormatStructArchive.control_maximum"
                ),
            controlIncrement:
                try optionalDouble(
                    fields,
                    number: 23,
                    context:
                        "TSK.FormatStructArchive.control_increment"
                ),
            controlFormatType:
                optionalVarint(
                    fields,
                    number: 24
                ),
            decimalWidth:
                optionalVarint(
                    fields,
                    number: 27
                ),
            minIntegerWidth:
                optionalVarint(
                    fields,
                    number: 28
                ),
            useAutomaticDurationUnits:
                optionalBool(
                    fields,
                    number: 40
                )
        )
    }

    private static func decodeCellSpecArchive(
        _ bytes: [UInt8],
        tableName: String,
        key: UInt32
    ) throws -> NumbersNativeModernDataListProfile.CellSpecArchive {
        let fields =
            try NumbersWire.decode(
                bytes,
                context:
                    "TST.CellSpecArchive \(tableName) key \(key)"
            )

        let chooserPopupReference:
            UInt64?

        if let popupField =
            fields.first(
                where: {
                    $0.number == 6
                    && $0.wireType == 2
                }
            )
        {
            chooserPopupReference =
                try reference(
                    popupField.bytes,
                    context:
                        "TST.CellSpecArchive \(tableName) key \(key) chooser popup"
                )
        } else {
            chooserPopupReference =
                nil
        }

        return NumbersNativeModernDataListProfile.CellSpecArchive(
            fieldSignatures:
                signatures(
                    fields
                ),
            interactionType:
                optionalVarint(
                    fields,
                    number: 1
                ),
            rangeControlMinimum:
                try optionalDouble(
                    fields,
                    number: 3,
                    context:
                        "TST.CellSpecArchive.range_control_min"
                ),
            rangeControlMaximum:
                try optionalDouble(
                    fields,
                    number: 4,
                    context:
                        "TST.CellSpecArchive.range_control_max"
                ),
            rangeControlIncrement:
                try optionalDouble(
                    fields,
                    number: 5,
                    context:
                        "TST.CellSpecArchive.range_control_inc"
                ),
            chooserPopupReference:
                chooserPopupReference,
            chooserStartsWithFirst:
                optionalBool(
                    fields,
                    number: 7
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

    private static func optionalDouble(
        _ fields: [NumbersWire.Field],
        number: UInt64,
        context: String
    ) throws -> Double? {
        guard let field =
            fields.first(
                where: {
                    $0.number == number
                    && $0.wireType == 1
                }
            )
        else {
            return nil
        }

        return try littleEndianDouble(
            field.bytes,
            context:
                context
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

    private static func signatures(
        _ fields: [NumbersWire.Field]
    ) -> [String] {
        fields.map {
            "\($0.number)/\($0.wireType)"
        }
    }
}
