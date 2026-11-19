import Foundation

@_spi(Testing)
public struct NumbersNativeDataStoreProfile:
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
        public let fieldSignatures: [String]
        public let fields: [Field]

        public init(
            name: String,
            tableModelIdentifier: UInt64,
            fieldSignatures: [String],
            fields: [Field]
        ) {
            self.name = name
            self.tableModelIdentifier =
                tableModelIdentifier
            self.fieldSignatures =
                fieldSignatures
            self.fields = fields
        }
    }

    public struct Field:
        Sendable
    {
        public let number: UInt64
        public let wireType: UInt64
        public let varint: UInt64?
        public let byteCount: Int

        public let nestedFieldSignatures: [String]?

        public let referenceIdentifierCandidate: UInt64?
        public let referencedObjects: [ReferencedObject]

        public init(
            number: UInt64,
            wireType: UInt64,
            varint: UInt64?,
            byteCount: Int,
            nestedFieldSignatures: [String]?,
            referenceIdentifierCandidate: UInt64?,
            referencedObjects: [ReferencedObject]
        ) {
            self.number = number
            self.wireType = wireType
            self.varint = varint
            self.byteCount = byteCount

            self.nestedFieldSignatures =
                nestedFieldSignatures

            self.referenceIdentifierCandidate =
                referenceIdentifierCandidate

            self.referencedObjects =
                referencedObjects
        }
    }

    public struct ReferencedObject:
        Sendable
    {
        public let identifier: UInt64
        public let type: UInt32
        public let payloadByteCount: Int
        public let fieldSignatures: [String]?

        public init(
            identifier: UInt64,
            type: UInt32,
            payloadByteCount: Int,
            fieldSignatures: [String]?
        ) {
            self.identifier = identifier
            self.type = type

            self.payloadByteCount =
                payloadByteCount

            self.fieldSignatures =
                fieldSignatures
        }
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func dataStoreProfile(
        at documentURL: URL
    ) throws -> NumbersNativeDataStoreProfile {
        let messages =
            try NumbersObjectArchiveReader.read(
                at: documentURL
            )

        return try NumbersNativeDataStoreProfiler.decode(
            messages
        )
    }
}

private enum NumbersNativeDataStoreProfiler {
    static let tableModelType:
        UInt32 = 6001

    static func decode(
        _ messages: [NumbersObjectMessage]
    ) throws -> NumbersNativeDataStoreProfile {
        let objects =
            Dictionary(
                grouping:
                    messages,
                by:
                    \.identifier
            )

        var tables:
            [NumbersNativeDataStoreProfile.Table] = []

        for tableModel in messages where
            tableModel.type == tableModelType
        {
            let tableFields =
                try NumbersWire.decode(
                    tableModel.payload,
                    context:
                        "TST.TableModelArchive DataStore profile"
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
                        "TST.DataStore \(tableName) profile"
                )

            tables.append(
                NumbersNativeDataStoreProfile.Table(
                    name:
                        tableName,
                    tableModelIdentifier:
                        tableModel.identifier,
                    fieldSignatures:
                        signatures(
                            dataStoreFields
                        ),
                    fields:
                        dataStoreFields.map {
                            profile(
                                $0,
                                tableName:
                                    tableName,
                                objects:
                                    objects
                            )
                        }
                )
            )
        }

        return NumbersNativeDataStoreProfile(
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

    private static func profile(
        _ field: NumbersWire.Field,
        tableName: String,
        objects: [UInt64: [NumbersObjectMessage]]
    ) -> NumbersNativeDataStoreProfile.Field {
        guard field.wireType == 2 else {
            return NumbersNativeDataStoreProfile.Field(
                number:
                    field.number,
                wireType:
                    field.wireType,
                varint:
                    field.varint,
                byteCount:
                    field.bytes.count,
                nestedFieldSignatures:
                    nil,
                referenceIdentifierCandidate:
                    nil,
                referencedObjects:
                    []
            )
        }

        let nestedFields =
            try? NumbersWire.decode(
                field.bytes,
                context:
                    "TST.DataStore \(tableName) field \(field.number) nested profile"
            )

        let referenceIdentifierCandidate:
            UInt64?

        let referencedObjects:
            [NumbersNativeDataStoreProfile.ReferencedObject]

        if let candidate =
            nestedFields?
                .first(
                    where: {
                        $0.number == 1
                        && $0.wireType == 0
                    }
                )?
                .varint,
           let matches =
            objects[
                candidate
            ],
           !matches.isEmpty
        {
            referenceIdentifierCandidate =
                candidate

            referencedObjects =
                matches
                    .map {
                        object in

                        let payloadFields =
                            try? NumbersWire.decode(
                                object.payload,
                                context:
                                    "referenced object \(object.identifier)/\(object.type)"
                            )

                        return NumbersNativeDataStoreProfile
                            .ReferencedObject(
                                identifier:
                                    object.identifier,
                                type:
                                    object.type,
                                payloadByteCount:
                                    object.payload.count,
                                fieldSignatures:
                                    payloadFields.map(
                                        signatures
                                    )
                            )
                    }
                    .sorted {
                        if $0.type != $1.type {
                            return $0.type < $1.type
                        }

                        return $0.payloadByteCount
                            < $1.payloadByteCount
                    }
        } else {
            referenceIdentifierCandidate =
                nil

            referencedObjects =
                []
        }

        return NumbersNativeDataStoreProfile.Field(
            number:
                field.number,
            wireType:
                field.wireType,
            varint:
                field.varint,
            byteCount:
                field.bytes.count,
            nestedFieldSignatures:
                nestedFields.map(
                    signatures
                ),
            referenceIdentifierCandidate:
                referenceIdentifierCandidate,
            referencedObjects:
                referencedObjects
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

    private static func signatures(
        _ fields: [NumbersWire.Field]
    ) -> [String] {
        fields.map {
            "\($0.number)/\($0.wireType)"
        }
    }
}
