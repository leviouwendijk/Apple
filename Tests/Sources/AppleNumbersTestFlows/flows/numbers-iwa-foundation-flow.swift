@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersIWAFoundationFlow:
        TestFlow
    {
        TestFlow(
            "numbers-iwa-foundation",
            tags: [
                "numbers",
                "iwa",
                "snappy",
                "lzfse",
                "protobuf",
                "native",
            ]
        ) {
            Step(
                "Swift decodes IWA Snappy framing and protobuf archive envelopes"
            ) {
                let syntheticIWA =
                    Data(
                        [
                            0x00,
                            0x0F,
                            0x00,
                            0x00,

                            0x0D,
                            0x30,

                            0x09,

                            0x08,
                            0x07,

                            0x12,
                            0x05,

                            0x08,
                            0xF0,
                            0x2E,

                            0x18,
                            0x03,

                            0xAA,
                            0xBB,
                            0xCC,
                        ]
                    )

                let profile =
                    try NumbersPackageReader.profileIWA(
                        syntheticIWA
                    )

                try Expect.equal(
                    profile.frameCount,
                    1,
                    "iwa.frame-count"
                )

                try Expect.equal(
                    profile.compressedByteCount,
                    15,
                    "iwa.compressed-byte-count"
                )

                try Expect.equal(
                    profile.decompressedByteCount,
                    13,
                    "iwa.decompressed-byte-count"
                )

                try Expect.equal(
                    profile.archiveCount,
                    1,
                    "iwa.archive-count"
                )

                try Expect.equal(
                    profile.messageCount,
                    1,
                    "iwa.message-count"
                )

                try Expect.equal(
                    profile.archiveIdentifiers,
                    [
                        7,
                    ],
                    "iwa.archive-identifier"
                )

                try Expect.equal(
                    profile.messageTypeIDs,
                    [
                        6000,
                    ],
                    "iwa.message-type"
                )
            }

            Step(
                "Swift decodes direct LZFSE IWA archive envelopes"
            ) {
                let syntheticLZFSEIWA =
                    Data(
                        [
                            0x62, 0x76, 0x78, 0x32, 0x0B, 0x10, 0x00, 0x00, 0x10, 0x00, 0x70, 0x00,
                            0x00, 0x03, 0x00, 0x50, 0x45, 0x89, 0xE3, 0x8B, 0x69, 0x0C, 0x00, 0x50,
                            0x94, 0x00, 0x00, 0x00, 0x37, 0x90, 0x00, 0x0C, 0xE7, 0x70, 0x0D, 0x00,
                            0x70, 0x0D, 0x00, 0x5C, 0x03, 0x00, 0x00, 0x00, 0xC0, 0x4F, 0xF0, 0x93,
                            0x7C, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x28, 0x00, 0xF0, 0x28, 0x3C, 0x0A,
                            0x8F, 0x06, 0x8F, 0x02, 0x00, 0xF0, 0x28, 0x00, 0xF0, 0x28, 0x00, 0x00,
                            0x8F, 0x02, 0x00, 0x00, 0x00, 0x8F, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x8F, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x3C, 0x3A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8F, 0x02,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x64, 0x96, 0x3A, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x34, 0x36, 0xFF, 0x1F, 0x62,
                            0x76, 0x78, 0x24,
                        ]
                    )

                let profile =
                    try NumbersPackageReader.profileIWA(
                        syntheticLZFSEIWA,
                        path:
                            "Synthetic-LZFSE.iwa"
                    )

                try Expect.equal(
                    profile.frameCount,
                    0,
                    "iwa.lzfse-frame-count"
                )

                try Expect.equal(
                    profile.compressedByteCount,
                    syntheticLZFSEIWA.count,
                    "iwa.lzfse-compressed-byte-count"
                )

                try Expect.equal(
                    profile.decompressedByteCount,
                    4107,
                    "iwa.lzfse-decompressed-byte-count"
                )

                try Expect.equal(
                    profile.archiveCount,
                    1,
                    "iwa.lzfse-archive-count"
                )

                try Expect.equal(
                    profile.messageCount,
                    1,
                    "iwa.lzfse-message-count"
                )

                try Expect.equal(
                    profile.archiveIdentifiers,
                    [
                        7,
                    ],
                    "iwa.lzfse-archive-identifiers"
                )

                try Expect.equal(
                    profile.messageTypeIDs,
                    [
                        6000,
                    ],
                    "iwa.lzfse-message-types"
                )
            }

        }
    }
}
