import Compression
import Foundation

enum NumbersLZFSEError:
    Error,
    Sendable
{
    case invalidStream(
        String
    )
}

enum NumbersLZFSE {
    private static let outputChunkSize =
        64 * 1024

    static func isSupportedStream(
        _ bytes: [UInt8]
    ) -> Bool {
        guard bytes.count >= 4 else {
            return false
        }

        guard
            bytes[0] == 0x62,
            bytes[1] == 0x76,
            bytes[2] == 0x78
        else {
            return false
        }

        switch bytes[3] {
        case 0x32:
            // bvx2 — observed LZFSE-compressed IWA stream.
            return true

        case 0x6E:
            // bvxn — observed LZVN-compressed block in LZFSE stream.
            return true

        default:
            return false
        }
    }

    static func decompress(
        _ bytes: [UInt8],
        source: String
    ) throws -> [UInt8] {
        guard isSupportedStream(
            bytes
        ) else {
            throw NumbersLZFSEError.invalidStream(
                "\(source): unsupported LZFSE stream magic"
            )
        }

        let stream =
            UnsafeMutablePointer<compression_stream>
                .allocate(
                    capacity:
                        1
                )

        let initializationStatus =
            compression_stream_init(
                stream,
                COMPRESSION_STREAM_DECODE,
                COMPRESSION_LZFSE
            )

        guard
            initializationStatus
                != COMPRESSION_STATUS_ERROR
        else {
            stream.deallocate()

            throw NumbersLZFSEError.invalidStream(
                "\(source): could not initialize LZFSE decoder"
            )
        }

        defer {
            compression_stream_destroy(
                stream
            )

            stream.deallocate()
        }

        let destination =
            UnsafeMutablePointer<UInt8>
                .allocate(
                    capacity:
                        outputChunkSize
                )

        defer {
            destination.deallocate()
        }

        let flags =
            Int32(
                COMPRESSION_STREAM_FINALIZE
                    .rawValue
            )

        return try bytes.withUnsafeBytes {
            rawSource in

            let sourceBytes =
                rawSource.bindMemory(
                    to:
                        UInt8.self
                )

            guard let sourceAddress =
                sourceBytes.baseAddress
            else {
                throw NumbersLZFSEError.invalidStream(
                    "\(source): empty LZFSE source"
                )
            }

            stream.pointee.src_ptr =
                sourceAddress

            stream.pointee.src_size =
                sourceBytes.count

            var output:
                [UInt8] = []

            while true {
                stream.pointee.dst_ptr =
                    destination

                stream.pointee.dst_size =
                    outputChunkSize

                let previousSourceSize =
                    stream.pointee.src_size

                let processStatus =
                    compression_stream_process(
                        stream,
                        flags
                    )

                let produced =
                    outputChunkSize
                    - stream.pointee.dst_size

                if produced > 0 {
                    output.append(
                        contentsOf:
                            UnsafeBufferPointer(
                                start:
                                    destination,
                                count:
                                    produced
                            )
                    )
                }

                if processStatus
                    == COMPRESSION_STATUS_END
                {
                    guard
                        stream.pointee.src_size
                            == 0
                    else {
                        throw NumbersLZFSEError.invalidStream(
                            "\(source): decoder ended before consuming complete source"
                        )
                    }

                    guard !output.isEmpty else {
                        throw NumbersLZFSEError.invalidStream(
                            "\(source): decoder produced no output"
                        )
                    }

                    return output
                }

                guard
                    processStatus
                        == COMPRESSION_STATUS_OK
                else {
                    throw NumbersLZFSEError.invalidStream(
                        "\(source): invalid LZFSE stream"
                    )
                }

                guard
                    produced > 0
                    || stream.pointee.src_size
                        < previousSourceSize
                else {
                    throw NumbersLZFSEError.invalidStream(
                        "\(source): decoder made no progress"
                    )
                }
            }
        }
    }
}
