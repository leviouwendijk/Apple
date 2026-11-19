import Foundation

@_spi(Testing)
public struct NumbersNativeFormattedStorageProbe:
    Sendable
{
    public struct Match:
        Sendable
    {
        public let needle: String

        public let utf8OccurrenceCount: Int

        public let utf16LittleEndianOccurrenceCount:
            Int

        public let utf16BigEndianOccurrenceCount:
            Int

        public init(
            needle: String,
            utf8OccurrenceCount: Int,
            utf16LittleEndianOccurrenceCount: Int,
            utf16BigEndianOccurrenceCount: Int
        ) {
            self.needle =
                needle

            self.utf8OccurrenceCount =
                utf8OccurrenceCount

            self.utf16LittleEndianOccurrenceCount =
                utf16LittleEndianOccurrenceCount

            self.utf16BigEndianOccurrenceCount =
                utf16BigEndianOccurrenceCount
        }

        public var totalOccurrenceCount:
            Int
        {
            utf8OccurrenceCount
            + utf16LittleEndianOccurrenceCount
            + utf16BigEndianOccurrenceCount
        }
    }

    public let messageCount: Int
    public let payloadByteCount: Int
    public let matches: [Match]

    public init(
        messageCount: Int,
        payloadByteCount: Int,
        matches: [Match]
    ) {
        self.messageCount =
            messageCount

        self.payloadByteCount =
            payloadByteCount

        self.matches =
            matches
    }
}

@_spi(Testing)
public extension NumbersPackageReader {
    static func formattedStorageProbe(
        at documentURL: URL,
        needles: [String]
    ) throws -> NumbersNativeFormattedStorageProbe {
        let messages =
            try NumbersObjectArchiveReader.read(
                at:
                    documentURL
            )

        let uniqueNeedles =
            Array(
                Set(
                    needles
                )
            )
            .sorted()

        let matches =
            try uniqueNeedles.map {
                needle in

                guard !needle.isEmpty else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "formatted-storage probe cannot search for an empty string"
                        )
                }

                let utf8 =
                    Array(
                        needle.utf8
                    )

                guard
                    let utf16LittleEndianData =
                        needle.data(
                            using:
                                .utf16LittleEndian
                        ),
                    let utf16BigEndianData =
                        needle.data(
                            using:
                                .utf16BigEndian
                        )
                else {
                    throw NumbersObjectGraphError
                        .invalidObjectGraph(
                            "formatted-storage probe could not encode a search string"
                        )
                }

                let utf16LittleEndian =
                    Array(
                        utf16LittleEndianData
                    )

                let utf16BigEndian =
                    Array(
                        utf16BigEndianData
                    )

                var utf8OccurrenceCount =
                    0

                var utf16LittleEndianOccurrenceCount =
                    0

                var utf16BigEndianOccurrenceCount =
                    0

                for message in messages {
                    utf8OccurrenceCount +=
                        occurrenceCount(
                            utf8,
                            in:
                                message.payload
                        )

                    utf16LittleEndianOccurrenceCount +=
                        occurrenceCount(
                            utf16LittleEndian,
                            in:
                                message.payload
                        )

                    utf16BigEndianOccurrenceCount +=
                        occurrenceCount(
                            utf16BigEndian,
                            in:
                                message.payload
                        )
                }

                return NumbersNativeFormattedStorageProbe
                    .Match(
                        needle:
                            needle,
                        utf8OccurrenceCount:
                            utf8OccurrenceCount,
                        utf16LittleEndianOccurrenceCount:
                            utf16LittleEndianOccurrenceCount,
                        utf16BigEndianOccurrenceCount:
                            utf16BigEndianOccurrenceCount
                    )
            }

        return NumbersNativeFormattedStorageProbe(
            messageCount:
                messages.count,
            payloadByteCount:
                messages.reduce(
                    0
                ) {
                    result,
                    message in

                    result
                    + message.payload.count
                },
            matches:
                matches
        )
    }

    private static func occurrenceCount(
        _ needle: [UInt8],
        in haystack: [UInt8]
    ) -> Int {
        guard
            !needle.isEmpty,
            needle.count <= haystack.count
        else {
            return 0
        }

        var result =
            0

        var index =
            0

        while
            index + needle.count
                <= haystack.count
        {
            let end =
                index + needle.count

            if haystack[
                index
                ..<
                end
            ]
            .elementsEqual(
                needle
            ) {
                result +=
                    1

                index =
                    end
            } else {
                index +=
                    1
            }
        }

        return result
    }
}
