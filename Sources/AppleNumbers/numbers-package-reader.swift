import Foundation
import ZIPFoundation

@_spi(Testing)
public enum NumbersPackageContainerKind:
    String,
    Equatable,
    Sendable
{
    case packageDirectory = "package-directory"
    case flatArchive = "flat-archive"
}

@_spi(Testing)
public struct NumbersIWAEntryProfile:
    Equatable,
    Sendable
{
    public let path: String

    public let frameCount: Int

    public let compressedByteCount: Int
    public let decompressedByteCount: Int

    public let archiveCount: Int
    public let messageCount: Int

    public let archiveIdentifiers: [UInt64]
    public let messageTypeIDs: [UInt32]

    public init(
        path: String,
        frameCount: Int,
        compressedByteCount: Int,
        decompressedByteCount: Int,
        archiveCount: Int,
        messageCount: Int,
        archiveIdentifiers: [UInt64],
        messageTypeIDs: [UInt32]
    ) {
        self.path = path
        self.frameCount = frameCount
        self.compressedByteCount = compressedByteCount
        self.decompressedByteCount = decompressedByteCount
        self.archiveCount = archiveCount
        self.messageCount = messageCount
        self.archiveIdentifiers = archiveIdentifiers
        self.messageTypeIDs = messageTypeIDs
    }
}

@_spi(Testing)
public struct NumbersPackageProfile:
    Equatable,
    Sendable
{
    public let kind: NumbersPackageContainerKind
    public let zipEntryCount: Int
    public let iwaEntries: [NumbersIWAEntryProfile]

    public init(
        kind: NumbersPackageContainerKind,
        zipEntryCount: Int,
        iwaEntries: [NumbersIWAEntryProfile]
    ) {
        self.kind = kind
        self.zipEntryCount = zipEntryCount
        self.iwaEntries = iwaEntries
    }

    public var iwaEntryCount: Int {
        iwaEntries.count
    }

    public var hasDocumentIWA: Bool {
        iwaEntries.contains {
            $0.path
                .lowercased()
                .hasSuffix(
                    "document.iwa"
                )
        }
    }

    public var totalFrameCount: Int {
        iwaEntries.reduce(
            0
        ) {
            $0 + $1.frameCount
        }
    }

    public var compressedByteCount: Int {
        iwaEntries.reduce(
            0
        ) {
            $0 + $1.compressedByteCount
        }
    }

    public var decompressedByteCount: Int {
        iwaEntries.reduce(
            0
        ) {
            $0 + $1.decompressedByteCount
        }
    }

    public var archiveCount: Int {
        iwaEntries.reduce(
            0
        ) {
            $0 + $1.archiveCount
        }
    }

    public var messageCount: Int {
        iwaEntries.reduce(
            0
        ) {
            $0 + $1.messageCount
        }
    }

    public var messageTypeIDs: [UInt32] {
        Array(
            Set(
                iwaEntries.flatMap(
                    \.messageTypeIDs
                )
            )
        )
        .sorted()
    }
}

@_spi(Testing)
public enum NumbersPackageReader {
    public static func profile(
        at documentURL: URL
    ) throws -> NumbersPackageProfile {
        var isDirectory =
            ObjCBool(
                false
            )

        guard FileManager.default.fileExists(
            atPath: documentURL.path,
            isDirectory: &isDirectory
        ) else {
            throw NumbersPackageReaderError
                .invalidDocument(
                    "document does not exist: \(documentURL.path)"
                )
        }

        if isDirectory.boolValue {
            return try profilePackageDirectory(
                at: documentURL
            )
        }

        return try profileFlatArchive(
            at: documentURL
        )
    }

    public static func profileIWA(
        _ data: Data,
        path: String = "Synthetic.iwa"
    ) throws -> NumbersIWAEntryProfile {
        try NumbersIWAInspector.profile(
            data,
            path: path
        )
    }
}

private extension NumbersPackageReader {
    struct ArchiveTraversal {
        var zipEntryCount = 0
        var iwaEntries: [NumbersIWAEntryProfile] = []
    }

    static func profilePackageDirectory(
        at documentURL: URL
    ) throws -> NumbersPackageProfile {
        let indexURL =
            documentURL.appendingPathComponent(
                "Index.zip"
            )

        guard FileManager.default.fileExists(
            atPath: indexURL.path
        ) else {
            throw NumbersPackageReaderError
                .invalidDocument(
                    "Numbers package directory is missing Index.zip"
                )
        }

        let archive =
            try Archive(
                url: indexURL,
                accessMode: .read
            )

        var traversal =
            ArchiveTraversal()

        try traverse(
            archive,
            prefix: "",
            traversal: &traversal
        )

        return NumbersPackageProfile(
            kind: .packageDirectory,
            zipEntryCount:
                traversal.zipEntryCount,
            iwaEntries:
                traversal.iwaEntries
                    .sorted {
                        $0.path < $1.path
                    }
        )
    }

    static func profileFlatArchive(
        at documentURL: URL
    ) throws -> NumbersPackageProfile {
        let archive =
            try Archive(
                url: documentURL,
                accessMode: .read
            )

        var traversal =
            ArchiveTraversal()

        try traverse(
            archive,
            prefix: "",
            traversal: &traversal
        )

        return NumbersPackageProfile(
            kind: .flatArchive,
            zipEntryCount:
                traversal.zipEntryCount,
            iwaEntries:
                traversal.iwaEntries
                    .sorted {
                        $0.path < $1.path
                    }
        )
    }

    static func traverse(
        _ archive: Archive,
        prefix: String,
        traversal: inout ArchiveTraversal
    ) throws {
        for entry in archive {
            traversal.zipEntryCount += 1

            let logicalPath =
                prefix
                + entry.path

            let normalized =
                entry.path.lowercased()

            if normalized.hasSuffix(
                "index.zip"
            ) {
                let nestedData =
                    try data(
                        from: archive,
                        path: entry.path
                    )

                let nestedArchive =
                    try Archive(
                        data: nestedData,
                        accessMode: .read
                    )

                try traverse(
                    nestedArchive,
                    prefix:
                        logicalPath
                        + "::",
                    traversal:
                        &traversal
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
                    path: entry.path
                )

            traversal.iwaEntries.append(
                try NumbersIWAInspector.profile(
                    bytes,
                    path: logicalPath
                )
            )
        }
    }

    static func data(
        from archive: Archive,
        path: String
    ) throws -> Data {
        guard let entry =
            archive[
                path
            ]
        else {
            throw NumbersPackageReaderError
                .invalidArchive(
                    "ZIP entry disappeared during traversal: \(path)"
                )
        }

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
}

private enum NumbersPackageReaderError:
    Error,
    CustomStringConvertible
{
    case invalidDocument(String)
    case invalidArchive(String)
    case invalidIWA(String)
    case invalidSnappy(String)
    case invalidProtobuf(String)

    var description: String {
        switch self {
        case .invalidDocument(
            let message
        ):
            return "Invalid Numbers document: \(message)"

        case .invalidArchive(
            let message
        ):
            return "Invalid Numbers ZIP archive: \(message)"

        case .invalidIWA(
            let message
        ):
            return "Invalid IWA stream: \(message)"

        case .invalidSnappy(
            let message
        ):
            return "Invalid Snappy stream: \(message)"

        case .invalidProtobuf(
            let message
        ):
            return "Invalid IWA protobuf stream: \(message)"
        }
    }
}

private enum NumbersIWAInspector {
    static func profile(
        _ data: Data,
        path: String
    ) throws -> NumbersIWAEntryProfile {
        let bytes =
            Array(
                data
            )

        var offset = 0

        var frameCount = 0
        var compressedByteCount = 0

        var protobufBytes: [UInt8] = []

        if NumbersLZFSE.isSupportedStream(
            bytes
        ) {
            protobufBytes =
                try NumbersLZFSE.decompress(
                    bytes,
                    source:
                        path
                )

            compressedByteCount =
                bytes.count
        } else {
            while offset < bytes.count {
                guard
                    offset + 4
                    <= bytes.count
                else {
                    throw NumbersPackageReaderError
                        .invalidIWA(
                            "\(path): truncated four-byte frame header"
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
                    throw NumbersPackageReaderError
                        .invalidIWA(
                            "\(path): unsupported IWA frame type \(frameType)"
                        )
                }
    
                guard
                    frameLength > 0,
                    offset + frameLength
                        <= bytes.count
                else {
                    throw NumbersPackageReaderError
                        .invalidIWA(
                            "\(path): invalid compressed frame length \(frameLength)"
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
    
                offset += frameLength
    
                let decompressed =
                    try NumbersSnappy.decompress(
                        compressed
                    )
    
                frameCount += 1
                compressedByteCount +=
                    compressed.count
    
                protobufBytes.append(
                    contentsOf:
                        decompressed
                )
            }
        }


        let envelopes =
            try NumbersIWAEnvelopeReader.read(
                protobufBytes,
                path: path
            )

        let identifiers =
            envelopes
                .compactMap(
                    \.identifier
                )

        let messageTypeIDs =
            Array(
                Set(
                    envelopes.flatMap {
                        $0.messages.map(
                            \.type
                        )
                    }
                )
            )
            .sorted()

        let messageCount =
            envelopes.reduce(
                0
            ) {
                $0 + $1.messages.count
            }

        return NumbersIWAEntryProfile(
            path: path,
            frameCount: frameCount,
            compressedByteCount:
                compressedByteCount,
            decompressedByteCount:
                protobufBytes.count,
            archiveCount:
                envelopes.count,
            messageCount:
                messageCount,
            archiveIdentifiers:
                identifiers,
            messageTypeIDs:
                messageTypeIDs
        )
    }
}

enum NumbersSnappy {
    static func decompress(
        _ bytes: [UInt8]
    ) throws -> [UInt8] {
        var index = 0

        let expectedRaw =
            try NumbersBinary.readVarint(
                bytes,
                index: &index,
                context:
                    "Snappy uncompressed length"
            )

        guard let expected =
            Int(
                exactly:
                    expectedRaw
            )
        else {
            throw NumbersPackageReaderError
                .invalidSnappy(
                    "uncompressed length does not fit Int"
                )
        }

        var output: [UInt8] = []

        output.reserveCapacity(
            expected
        )

        while output.count < expected {
            guard index < bytes.count else {
                throw NumbersPackageReaderError
                    .invalidSnappy(
                        "compressed stream ended before expected output length"
                    )
            }

            let tag =
                bytes[
                    index
                ]

            index += 1

            switch tag & 0x03 {
            case 0:
                let lengthCode =
                    Int(
                        tag >> 2
                    )

                let literalLength: Int

                if lengthCode < 60 {
                    literalLength =
                        lengthCode + 1
                } else {
                    let byteCount =
                        lengthCode - 59

                    guard
                        byteCount >= 1,
                        byteCount <= 4,
                        index + byteCount
                            <= bytes.count
                    else {
                        throw NumbersPackageReaderError
                            .invalidSnappy(
                                "invalid long literal length"
                            )
                    }

                    var lengthMinusOne =
                        0

                    for byteOffset in 0..<byteCount {
                        lengthMinusOne |=
                            Int(
                                bytes[
                                    index
                                    + byteOffset
                                ]
                            )
                            << (
                                byteOffset
                                * 8
                            )
                    }

                    index +=
                        byteCount

                    literalLength =
                        lengthMinusOne + 1
                }

                guard
                    literalLength >= 0,
                    index + literalLength
                        <= bytes.count,
                    output.count + literalLength
                        <= expected
                else {
                    throw NumbersPackageReaderError
                        .invalidSnappy(
                            "literal exceeds compressed or uncompressed bounds"
                        )
                }

                output.append(
                    contentsOf:
                        bytes[
                            index
                            ..<
                            index + literalLength
                        ]
                )

                index +=
                    literalLength

            case 1:
                guard index < bytes.count else {
                    throw NumbersPackageReaderError
                        .invalidSnappy(
                            "truncated COPY_1 instruction"
                        )
                }

                let length =
                    4
                    + Int(
                        (
                            tag >> 2
                        )
                        & 0x07
                    )

                let offset =
                    (
                        Int(
                            tag
                            & 0xE0
                        )
                        << 3
                    )
                    | Int(
                        bytes[
                            index
                        ]
                    )

                index += 1

                try appendCopy(
                    length: length,
                    offset: offset,
                    expected: expected,
                    output: &output
                )

            case 2:
                guard
                    index + 2
                    <= bytes.count
                else {
                    throw NumbersPackageReaderError
                        .invalidSnappy(
                            "truncated COPY_2 instruction"
                        )
                }

                let length =
                    1
                    + Int(
                        tag >> 2
                    )

                let offset =
                    Int(
                        bytes[
                            index
                        ]
                    )
                    | (
                        Int(
                            bytes[
                                index + 1
                            ]
                        )
                        << 8
                    )

                index += 2

                try appendCopy(
                    length: length,
                    offset: offset,
                    expected: expected,
                    output: &output
                )

            case 3:
                guard
                    index + 4
                    <= bytes.count
                else {
                    throw NumbersPackageReaderError
                        .invalidSnappy(
                            "truncated COPY_4 instruction"
                        )
                }

                let length =
                    1
                    + Int(
                        tag >> 2
                    )

                let rawOffset =
                    UInt64(
                        bytes[
                            index
                        ]
                    )
                    | (
                        UInt64(
                            bytes[
                                index + 1
                            ]
                        )
                        << 8
                    )
                    | (
                        UInt64(
                            bytes[
                                index + 2
                            ]
                        )
                        << 16
                    )
                    | (
                        UInt64(
                            bytes[
                                index + 3
                            ]
                        )
                        << 24
                    )

                guard let offset =
                    Int(
                        exactly:
                            rawOffset
                    )
                else {
                    throw NumbersPackageReaderError
                        .invalidSnappy(
                            "COPY_4 offset does not fit Int"
                        )
                }

                index += 4

                try appendCopy(
                    length: length,
                    offset: offset,
                    expected: expected,
                    output: &output
                )

            default:
                fatalError(
                    "unreachable Snappy tag type"
                )
            }
        }

        guard output.count == expected else {
            throw NumbersPackageReaderError
                .invalidSnappy(
                    "decoded \(output.count) bytes, expected \(expected)"
                )
        }

        guard index == bytes.count else {
            throw NumbersPackageReaderError
                .invalidSnappy(
                    "compressed block contains \(bytes.count - index) trailing bytes"
                )
        }

        return output
    }

    private static func appendCopy(
        length: Int,
        offset: Int,
        expected: Int,
        output: inout [UInt8]
    ) throws {
        guard
            offset > 0,
            offset <= output.count
        else {
            throw NumbersPackageReaderError
                .invalidSnappy(
                    "copy offset \(offset) is outside decoded history"
                )
        }

        guard
            length >= 0,
            output.count + length
                <= expected
        else {
            throw NumbersPackageReaderError
                .invalidSnappy(
                    "copy instruction exceeds expected output length"
                )
        }

        for _ in 0..<length {
            let sourceIndex =
                output.count
                - offset

            output.append(
                output[
                    sourceIndex
                ]
            )
        }
    }
}

private struct NumbersIWAEnvelope {
    let identifier: UInt64?
    let messages: [NumbersIWAMessageInfo]
}

private struct NumbersIWAMessageInfo {
    let type: UInt32
    let length: Int
}

private enum NumbersIWAEnvelopeReader {
    static func read(
        _ bytes: [UInt8],
        path: String
    ) throws -> [NumbersIWAEnvelope] {
        var index = 0

        var result: [NumbersIWAEnvelope] = []

        while index < bytes.count {
            let infoLengthRaw =
                try NumbersBinary.readVarint(
                    bytes,
                    index: &index,
                    context:
                        "\(path) ArchiveInfo length"
                )

            guard let infoLength =
                Int(
                    exactly:
                        infoLengthRaw
                )
            else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
                        "\(path): ArchiveInfo length does not fit Int"
                    )
            }

            guard
                infoLength >= 0,
                index + infoLength
                    <= bytes.count
            else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
                        "\(path): ArchiveInfo extends beyond decompressed IWA"
                    )
            }

            let infoBytes =
                Array(
                    bytes[
                        index
                        ..<
                        index + infoLength
                    ]
                )

            index +=
                infoLength

            let envelope =
                try parseArchiveInfo(
                    infoBytes,
                    path: path
                )

            var payloadLength =
                0

            for message in envelope.messages {
                guard
                    message.length
                        <= Int.max
                            - payloadLength
                else {
                    throw NumbersPackageReaderError
                        .invalidProtobuf(
                            "\(path): payload length overflow"
                        )
                }

                payloadLength +=
                    message.length
            }

            guard
                index + payloadLength
                    <= bytes.count
            else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
                        "\(path): payload extends beyond decompressed IWA"
                    )
            }

            index +=
                payloadLength

            result.append(
                envelope
            )
        }

        return result
    }

    private static func parseArchiveInfo(
        _ bytes: [UInt8],
        path: String
    ) throws -> NumbersIWAEnvelope {
        var reader =
            NumbersProtobufReader(
                bytes
            )

        var identifier: UInt64?
        var messages: [NumbersIWAMessageInfo] = []

        while !reader.isAtEnd {
            let key =
                try reader.readVarint(
                    context:
                        "\(path) ArchiveInfo field key"
                )

            let fieldNumber =
                key >> 3

            let wireType =
                key & 0x07

            switch (
                fieldNumber,
                wireType
            ) {
            case (
                1,
                0
            ):
                identifier =
                    try reader.readVarint(
                        context:
                            "\(path) ArchiveInfo identifier"
                    )

            case (
                2,
                2
            ):
                let messageInfo =
                    try reader.readLengthDelimited(
                        context:
                            "\(path) MessageInfo"
                    )

                messages.append(
                    try parseMessageInfo(
                        messageInfo,
                        path: path
                    )
                )

            default:
                try reader.skip(
                    wireType:
                        wireType,
                    context:
                        "\(path) ArchiveInfo field \(fieldNumber)"
                )
            }
        }

        guard !messages.isEmpty else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(path): ArchiveInfo contains no MessageInfo records"
                )
        }

        return NumbersIWAEnvelope(
            identifier: identifier,
            messages: messages
        )
    }

    private static func parseMessageInfo(
        _ bytes: [UInt8],
        path: String
    ) throws -> NumbersIWAMessageInfo {
        var reader =
            NumbersProtobufReader(
                bytes
            )

        var type: UInt32?
        var length: Int?

        while !reader.isAtEnd {
            let key =
                try reader.readVarint(
                    context:
                        "\(path) MessageInfo field key"
                )

            let fieldNumber =
                key >> 3

            let wireType =
                key & 0x07

            switch (
                fieldNumber,
                wireType
            ) {
            case (
                1,
                0
            ):
                let raw =
                    try reader.readVarint(
                        context:
                            "\(path) MessageInfo type"
                    )

                guard let decoded =
                    UInt32(
                        exactly:
                            raw
                    )
                else {
                    throw NumbersPackageReaderError
                        .invalidProtobuf(
                            "\(path): MessageInfo type does not fit UInt32"
                        )
                }

                type =
                    decoded

            case (
                3,
                0
            ):
                let raw =
                    try reader.readVarint(
                        context:
                            "\(path) MessageInfo payload length"
                    )

                guard let decoded =
                    Int(
                        exactly:
                            raw
                    )
                else {
                    throw NumbersPackageReaderError
                        .invalidProtobuf(
                            "\(path): MessageInfo length does not fit Int"
                        )
                }

                length =
                    decoded

            default:
                try reader.skip(
                    wireType:
                        wireType,
                    context:
                        "\(path) MessageInfo field \(fieldNumber)"
                )
            }
        }

        guard let type else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(path): MessageInfo missing required type"
                )
        }

        guard let length else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(path): MessageInfo missing required length"
                )
        }

        return NumbersIWAMessageInfo(
            type: type,
            length: length
        )
    }
}

private struct NumbersProtobufReader {
    let bytes: [UInt8]

    var index = 0

    init(
        _ bytes: [UInt8]
    ) {
        self.bytes = bytes
    }

    var isAtEnd: Bool {
        index == bytes.count
    }

    mutating func readVarint(
        context: String
    ) throws -> UInt64 {
        try NumbersBinary.readVarint(
            bytes,
            index: &index,
            context: context
        )
    }

    mutating func readLengthDelimited(
        context: String
    ) throws -> [UInt8] {
        let rawLength =
            try readVarint(
                context:
                    "\(context) length"
            )

        guard let length =
            Int(
                exactly:
                    rawLength
            )
        else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(context): length does not fit Int"
                )
        }

        guard
            length >= 0,
            index + length
                <= bytes.count
        else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(context): length-delimited field exceeds buffer"
                )
        }

        let result =
            Array(
                bytes[
                    index
                    ..<
                    index + length
                ]
            )

        index +=
            length

        return result
    }

    mutating func skip(
        wireType: UInt64,
        context: String
    ) throws {
        switch wireType {
        case 0:
            _ = try readVarint(
                context:
                    "\(context) varint"
            )

        case 1:
            try advance(
                8,
                context:
                    "\(context) fixed64"
            )

        case 2:
            let rawLength =
                try readVarint(
                    context:
                        "\(context) length"
                )

            guard let length =
                Int(
                    exactly:
                        rawLength
                )
            else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
                        "\(context): length does not fit Int"
                    )
            }

            try advance(
                length,
                context:
                    "\(context) bytes"
            )

        case 5:
            try advance(
                4,
                context:
                    "\(context) fixed32"
            )

        default:
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(context): unsupported protobuf wire type \(wireType)"
                )
        }
    }

    private mutating func advance(
        _ count: Int,
        context: String
    ) throws {
        guard
            count >= 0,
            index + count
                <= bytes.count
        else {
            throw NumbersPackageReaderError
                .invalidProtobuf(
                    "\(context): field exceeds protobuf buffer"
                )
        }

        index +=
            count
    }
}

private enum NumbersBinary {
    static func readVarint(
        _ bytes: [UInt8],
        index: inout Int,
        context: String
    ) throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0

        while true {
            guard index < bytes.count else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
                        "\(context): truncated varint"
                    )
            }

            let byte =
                bytes[
                    index
                ]

            index += 1

            guard shift < 64 else {
                throw NumbersPackageReaderError
                    .invalidProtobuf(
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
