@_spi(Testing) import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersDirectPackageOracleFlow:
        TestFlow
    {
        TestFlow(
            "numbers-direct-package-oracle",
            tags: [
                "numbers",
                "snapshot",
                "direct-package",
                "oracle",
                "iwa",
                "integration",
            ]
        ) {
            Step(
                "numbers-parser directly decodes the current Numbers fixture with native snapshot parity"
            ) {
                guard
                    let python =
                        ProcessInfo.processInfo
                            .environment[
                                "APPLE_NUMBERS_ORACLE_PYTHON"
                            ],
                    !python.isEmpty
                else {
                    throw NumbersParserOracle
                        .OracleError
                        .invalidTransport(
                            "APPLE_NUMBERS_ORACLE_PYTHON is missing"
                        )
                }

                let directory =
                    try numbersTestFixtureDirectory(
                        prefix: "DirectOracleFlow"
                    )

                defer {
                    try? FileManager.default
                        .removeItem(
                            at: directory
                        )
                }

                let documentURL =
                    directory
                        .appendingPathComponent(
                            "Native-Probe.numbers"
                        )

                try createNumbersFixture(
                    at: documentURL
                )

                let native =
                    try AppleNumbers.snapshot(
                        at: documentURL
                    )

                let oracle =
                    try NumbersParserOracle.read(
                        at: documentURL,
                        pythonExecutable: python
                    )

                let swiftPackage =
                    try NumbersPackageReader.profile(
                        at: documentURL
                    )

                try Expect.equal(
                    swiftPackage.kind,
                    .flatArchive,
                    "swift-package.container-kind"
                )

                try Expect.equal(
                    swiftPackage.iwaEntryCount,
                    oracle.package.iwaEntryCount,
                    "swift-package.iwa-entry-count"
                )

                try Expect.true(
                    swiftPackage.hasDocumentIWA,
                    "swift-package.document-iwa"
                )

                try Expect.true(
                    swiftPackage.totalFrameCount > 0,
                    "swift-package.frame-count"
                )

                try Expect.true(
                    swiftPackage.decompressedByteCount > 0,
                    "swift-package.decompressed-bytes"
                )

                try Expect.true(
                    swiftPackage.archiveCount > 0,
                    "swift-package.archive-count"
                )

                try Expect.true(
                    swiftPackage.messageCount
                        >= swiftPackage.archiveCount,
                    "swift-package.message-count"
                )

                let oracleArchiveCount =
                    Set(
                        oracle.package
                            .archives
                            .map {
                                $0.file
                                + "#"
                                + String(
                                    $0.identifier
                                )
                            }
                    )
                    .count

                try Expect.equal(
                    swiftPackage.archiveCount,
                    oracleArchiveCount,
                    "swift-package.archive-envelope-parity"
                )

                try Expect.equal(
                    oracle.sheets.count,
                    native.sheets.count,
                    "oracle.sheet-count"
                )

                try Expect.equal(
                    oracle.sheets.map(
                        \.name
                    ),
                    native.sheets.map(
                        \.name
                    ),
                    "oracle.sheet-order-and-names"
                )

                let oracleTables =
                    oracle.sheets[0]
                        .tables

                let nativeTables =
                    native.sheets[0]
                        .tables

                try Expect.equal(
                    Set(
                        oracleTables.map(
                            \.name
                        )
                    ),
                    Set(
                        nativeTables.map(
                            \.name
                        )
                    ),
                    "oracle.table-membership-and-names"
                )

                guard
                    let oracleClients =
                        oracleTables.first(
                            where: {
                                $0.name == "Clients"
                            }
                        ),
                    let nativeClients =
                        nativeTables.first(
                            where: {
                                $0.name == "Clients"
                            }
                        )
                else {
                    throw NumbersParserOracle
                        .OracleError
                        .invalidTransport(
                            "expected Clients table in both extraction backends"
                        )
                }

                try Expect.equal(
                    oracleClients.rowCount,
                    nativeClients.rowCount,
                    "oracle.clients.row-count"
                )

                try Expect.equal(
                    oracleClients.columnCount,
                    nativeClients.columnCount,
                    "oracle.clients.column-count"
                )

                try Expect.equal(
                    try oracleClients
                        .rows[1][0]
                        .value
                        .numbersValue(),
                    nativeClients
                        .rows[1]
                        .cells[0]
                        .value,
                    "oracle.number"
                )

                try Expect.equal(
                    try oracleClients
                        .rows[1][2]
                        .value
                        .numbersValue(),
                    nativeClients
                        .rows[1]
                        .cells[2]
                        .value,
                    "oracle.boolean"
                )

                try Expect.equal(
                    try oracleClients
                        .rows[2][3]
                        .value
                        .numbersValue(),
                    nativeClients
                        .rows[2]
                        .cells[3]
                        .value,
                    "oracle.empty"
                )

                try Expect.equal(
                    oracleClients
                        .rows[1][4]
                        .value
                        .kind,
                    "date",
                    "oracle.date-kind"
                )

                guard
                    let oracleInvoices =
                        oracleTables.first(
                            where: {
                                $0.name == "Invoices"
                            }
                        ),
                    let nativeInvoices =
                        nativeTables.first(
                            where: {
                                $0.name == "Invoices"
                            }
                        )
                else {
                    throw NumbersParserOracle
                        .OracleError
                        .invalidTransport(
                            "expected Invoices table in both extraction backends"
                        )
                }

                try Expect.equal(
                    oracleInvoices.rowCount,
                    nativeInvoices.rowCount,
                    "oracle.invoices.row-count"
                )

                try Expect.equal(
                    oracleInvoices.columnCount,
                    nativeInvoices.columnCount,
                    "oracle.invoices.column-count"
                )

                try Expect.equal(
                    try oracleInvoices
                        .rows[1][2]
                        .value
                        .numbersValue(),
                    nativeInvoices
                        .rows[1]
                        .cells[2]
                        .value,
                    "oracle.currency-value"
                )

                let oracleFormulaCell =
                    oracleInvoices
                        .rows[1][3]

                let nativeFormulaCell =
                    nativeInvoices
                        .rows[1]
                        .cells[3]

                try Expect.equal(
                    try oracleFormulaCell
                        .value
                        .numbersValue(),
                    nativeFormulaCell.value,
                    "oracle.formula-calculated-value"
                )

                try Expect.true(
                    oracleFormulaCell
                        .formula?
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                        == false,
                    "oracle.formula-source"
                )

                try Expect.true(
                    oracleInvoices
                        .rows[1][2]
                        .formatted?
                        .isEmpty
                        == false,
                    "oracle.formatted-value"
                )

                try Expect.true(
                    oracle.package
                        .indexEntryCount
                        > 0,
                    "oracle.package.index-entry-count"
                )

                try Expect.true(
                    oracle.package
                        .iwaEntryCount
                        > 0,
                    "oracle.package.iwa-entry-count"
                )

                try Expect.true(
                    oracle.package
                        .hasDocumentIWA,
                    "oracle.package.document-iwa"
                )

                try Expect.true(
                    !oracle.package
                        .archives
                        .isEmpty,
                    "oracle.package.decoded-archives"
                )

                let archiveTypeNames =
                    Array(
                        Set(
                            oracle.package
                                .archives
                                .map(
                                    \.typeName
                                )
                        )
                    )
                    .sorted()

                print(
                    "SWIFT PACKAGE PROFILE"
                )

                print(
                    "  container: "
                    + swiftPackage.kind.rawValue
                )

                print(
                    "  zip entries traversed: "
                    + String(
                        swiftPackage.zipEntryCount
                    )
                )

                print(
                    "  IWA entries: "
                    + String(
                        swiftPackage.iwaEntryCount
                    )
                )

                print(
                    "  Snappy frames: "
                    + String(
                        swiftPackage.totalFrameCount
                    )
                )

                print(
                    "  compressed IWA bytes: "
                    + String(
                        swiftPackage.compressedByteCount
                    )
                )

                print(
                    "  decompressed protobuf bytes: "
                    + String(
                        swiftPackage.decompressedByteCount
                    )
                )

                print(
                    "  archive envelopes: "
                    + String(
                        swiftPackage.archiveCount
                    )
                )

                print(
                    "  payload messages: "
                    + String(
                        swiftPackage.messageCount
                    )
                )

                print(
                    "  unique message type IDs: "
                    + String(
                        swiftPackage
                            .messageTypeIDs
                            .count
                    )
                )

                print(
                    "ORACLE PACKAGE PROFILE"
                )

                print(
                    "  file-format-version: "
                    + (
                        oracle.package
                            .fileFormatVersion
                        ?? "<unknown>"
                    )
                )

                print(
                    "  index entries: "
                    + String(
                        oracle.package
                            .indexEntryCount
                    )
                )

                print(
                    "  IWA entries: "
                    + String(
                        oracle.package
                            .iwaEntryCount
                    )
                )

                print(
                    "  decoded archive objects: "
                    + String(
                        oracle.package
                            .archives
                            .count
                    )
                )

                print(
                    "  unique protobuf/archive types: "
                    + String(
                        archiveTypeNames.count
                    )
                )

                for typeName in archiveTypeNames {
                    print(
                        "    "
                        + typeName
                    )
                }
            }
        }
    }
}
