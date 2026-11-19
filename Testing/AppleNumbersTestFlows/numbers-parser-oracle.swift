import AppleNumbers
import Foundation

enum NumbersParserOracle {
    struct Document:
        Decodable
    {
        let name: String
        let package: PackageProfile
        let sheets: [Sheet]
    }

    struct PackageProfile:
        Decodable
    {
        let fileFormatVersion: String?
        let indexEntryCount: Int
        let iwaEntryCount: Int
        let hasDocumentIWA: Bool
        let archives: [ArchiveProfile]
    }

    struct ArchiveProfile:
        Decodable,
        Hashable
    {
        let file: String
        let identifier: Int
        let typeName: String
    }

    struct Sheet:
        Decodable
    {
        let name: String
        let tables: [Table]
    }

    struct Table:
        Decodable
    {
        let name: String
        let rows: [[Cell]]

        var rowCount: Int {
            rows.count
        }

        var columnCount: Int {
            rows
                .map(
                    \.count
                )
                .max()
                ?? 0
        }
    }

    struct Cell:
        Decodable
    {
        let value: Value
        let formula: String?
        let formatted: String?
        let typeName: String
    }

    struct Value:
        Decodable
    {
        let kind: String
        let text: String?
        let number: String?
        let boolean: Bool?
        let date: String?

        func numbersValue()
            throws -> NumbersCellValue
        {
            switch kind {
            case "empty":
                return .empty

            case "text":
                guard let text else {
                    throw OracleError.invalidTransport(
                        "text value missing payload"
                    )
                }

                return .text(
                    text
                )

            case "number":
                guard
                    let number,
                    let decimal =
                        Decimal(
                            string: number,
                            locale:
                                Locale(
                                    identifier:
                                        "en_US_POSIX"
                                )
                        )
                else {
                    throw OracleError.invalidTransport(
                        "number value missing or invalid payload"
                    )
                }

                return .number(
                    decimal
                )

            case "boolean":
                guard let boolean else {
                    throw OracleError.invalidTransport(
                        "boolean value missing payload"
                    )
                }

                return .boolean(
                    boolean
                )

            case "date":
                guard
                    let date,
                    let parsed =
                        Self.dateValue(
                            date
                        )
                else {
                    throw OracleError.invalidTransport(
                        "date value missing or invalid payload"
                    )
                }

                return .date(
                    parsed
                )

            default:
                throw OracleError.invalidTransport(
                    "unsupported oracle primitive kind '\(kind)'"
                )
            }
        }

        private static func dateValue(
            _ value: String
        ) -> Date? {
            let fractional =
                ISO8601DateFormatter()

            fractional.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds,
            ]

            if let date =
                fractional.date(
                    from: value
                )
            {
                return date
            }

            let regular =
                ISO8601DateFormatter()

            regular.formatOptions = [
                .withInternetDateTime,
            ]

            return regular.date(
                from: value
            )
        }
    }

    enum OracleError:
        Error,
        CustomStringConvertible
    {
        case pythonFailed(
            status: Int32,
            stderr: String
        )

        case invalidTransport(
            String
        )

        var description: String {
            switch self {
            case .pythonFailed(
                let status,
                let stderr
            ):
                return """
                numbers-parser oracle failed with status \(status): \
                \(stderr)
                """

            case .invalidTransport(
                let message
            ):
                return "Invalid numbers-parser oracle transport: \(message)"
            }
        }
    }

    static func read(
        at documentURL: URL,
        pythonExecutable: String
    ) throws -> Document {
        let fileManager =
            FileManager.default

        let directory =
            fileManager
                .temporaryDirectory
                .appendingPathComponent(
                    "AppleNumbersOracle-\(UUID().uuidString)",
                    isDirectory: true
                )

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(
                at: directory
            )
        }

        let scriptURL =
            directory
                .appendingPathComponent(
                    "numbers-parser-oracle.py"
                )

        let stdoutURL =
            directory
                .appendingPathComponent(
                    "stdout"
                )

        let stderrURL =
            directory
                .appendingPathComponent(
                    "stderr"
                )

        try pythonSource.write(
            to: scriptURL,
            atomically: true,
            encoding: .utf8
        )

        try Data().write(
            to: stdoutURL
        )

        try Data().write(
            to: stderrURL
        )

        let stdoutHandle =
            try FileHandle(
                forWritingTo: stdoutURL
            )

        let stderrHandle =
            try FileHandle(
                forWritingTo: stderrURL
            )

        let process =
            Process()

        process.executableURL =
            URL(
                fileURLWithPath:
                    pythonExecutable
            )

        process.arguments = [
            scriptURL.path,
            documentURL.path,
        ]

        process.standardOutput =
            stdoutHandle

        process.standardError =
            stderrHandle

        do {
            try process.run()

            process.waitUntilExit()
        } catch {
            try? stdoutHandle.close()
            try? stderrHandle.close()

            throw error
        }

        try stdoutHandle.close()
        try stderrHandle.close()

        let stdout =
            try Data(
                contentsOf: stdoutURL
            )

        let stderr =
            try Data(
                contentsOf: stderrURL
            )

        guard process.terminationStatus == 0 else {
            throw OracleError.pythonFailed(
                status:
                    process.terminationStatus,
                stderr:
                    String(
                        data: stderr,
                        encoding: .utf8
                    )
                    ?? "<non-UTF8 stderr>"
            )
        }

        do {
            return try JSONDecoder().decode(
                Document.self,
                from: stdout
            )
        } catch {
            throw OracleError.invalidTransport(
                String(
                    describing: error
                )
            )
        }
    }

    private static let pythonSource = #"""
import json
import numbers
import plistlib
import sys
import zipfile

from datetime import date, datetime, timezone
from pathlib import Path

from numbers_parser import Document
from numbers_parser.iwafile import IWAFile, is_iwa_file


def safe_text_property(cell, name):
    try:
        value = getattr(cell, name)
    except Exception:
        return None

    if value is None:
        return None

    return str(value)


def encode_date(value):
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(
                tzinfo=timezone.utc
            )

        return value.isoformat()

    if isinstance(value, date):
        converted = datetime(
            value.year,
            value.month,
            value.day,
            tzinfo=timezone.utc,
        )

        return converted.isoformat()

    raise TypeError(
        "Unsupported date type: "
        + type(value).__name__
    )


def encode_value(value):
    if value is None:
        return {
            "kind": "empty",
            "text": None,
            "number": None,
            "boolean": None,
            "date": None,
        }

    if isinstance(value, bool):
        return {
            "kind": "boolean",
            "text": None,
            "number": None,
            "boolean": value,
            "date": None,
        }

    if isinstance(value, (datetime, date)):
        return {
            "kind": "date",
            "text": None,
            "number": None,
            "boolean": None,
            "date": encode_date(value),
        }

    if isinstance(value, numbers.Real):
        return {
            "kind": "number",
            "text": None,
            "number": repr(value),
            "boolean": None,
            "date": None,
        }

    if isinstance(value, str):
        return {
            "kind": "text",
            "text": value,
            "number": None,
            "boolean": None,
            "date": None,
        }

    raise TypeError(
        "Unsupported oracle value type: "
        + type(value).__name__
    )


def encode_cell(cell):
    return {
        "value": encode_value(
            cell.value
        ),
        "formula": safe_text_property(
            cell,
            "formula",
        ),
        "formatted": safe_text_property(
            cell,
            "formatted_value",
        ),
        "typeName": type(cell).__name__,
    }


def archive_type_name(obj):
    descriptor = getattr(
        obj,
        "DESCRIPTOR",
        None,
    )

    if descriptor is None:
        return type(obj).__name__

    full_name = getattr(
        descriptor,
        "full_name",
        None,
    )

    if full_name:
        return str(full_name)

    return type(obj).__name__


def package_profile(source):
    archive_profiles = []
    all_names = []
    iwa_names = []

    file_format_version = None

    def inspect_iwa_archive(
        archive,
        prefix="",
    ):
        nonlocal all_names
        nonlocal iwa_names
        nonlocal archive_profiles

        names = archive.namelist()

        for name in names:
            logical_name = (
                prefix + name
            )

            all_names.append(
                logical_name
            )

            blob = archive.read(
                name
            )

            if name.lower().endswith(
                "index.zip"
            ):
                from io import BytesIO

                with zipfile.ZipFile(
                    BytesIO(
                        blob
                    ),
                    "r",
                ) as nested:
                    inspect_iwa_archive(
                        nested,
                        prefix=logical_name + "::",
                    )

                continue

            if not name.lower().endswith(
                ".iwa"
            ):
                continue

            if not is_iwa_file(
                blob
            ):
                continue

            iwa_names.append(
                logical_name
            )

            decoded = IWAFile.from_buffer(
                blob,
                logical_name,
            )

            if not decoded.chunks:
                continue

            for chunk in decoded.chunks:
                for item in chunk.archives:
                    identifier = int(
                        item.header.identifier
                    )

                    for obj in item.objects:
                        archive_profiles.append(
                            {
                                "file":
                                    logical_name,
                                "identifier":
                                    identifier,
                                "typeName":
                                    archive_type_name(
                                        obj
                                    ),
                            }
                        )

    if source.is_dir():
        properties_file = (
            source
            / "Metadata"
            / "Properties.plist"
        )

        if properties_file.is_file():
            properties = plistlib.loads(
                properties_file.read_bytes()
            )

            raw_version = properties.get(
                "fileFormatVersion"
            )

            if raw_version is not None:
                file_format_version = str(
                    raw_version
                )

        index_file = (
            source
            / "Index.zip"
        )

        if not index_file.is_file():
            raise RuntimeError(
                "Numbers package directory is missing Index.zip"
            )

        with zipfile.ZipFile(
            index_file,
            "r",
        ) as archive:
            inspect_iwa_archive(
                archive
            )

    elif source.is_file():
        with zipfile.ZipFile(
            source,
            "r",
        ) as archive:
            metadata_names = [
                name
                for name in archive.namelist()
                if name.endswith(
                    "Metadata/Properties.plist"
                )
            ]

            if metadata_names:
                properties = plistlib.loads(
                    archive.read(
                        metadata_names[0]
                    )
                )

                raw_version = properties.get(
                    "fileFormatVersion"
                )

                if raw_version is not None:
                    file_format_version = str(
                        raw_version
                    )

            inspect_iwa_archive(
                archive
            )

    else:
        raise RuntimeError(
            "Numbers source is neither file nor package directory"
        )

    return {
        "fileFormatVersion":
            file_format_version,
        "indexEntryCount":
            len(
                all_names
            ),
        "iwaEntryCount":
            len(
                iwa_names
            ),
        "hasDocumentIWA":
            any(
                name.endswith(
                    "Document.iwa"
                )
                for name in iwa_names
            ),
        "archives":
            archive_profiles,
    }


def encode_document(source):
    document = Document(
        source
    )

    sheets = []

    for sheet in document.sheets:
        tables = []

        for table in sheet.tables:
            encoded_rows = []

            for row in table.rows():
                encoded_rows.append(
                    [
                        encode_cell(cell)
                        for cell in row
                    ]
                )

            tables.append(
                {
                    "name":
                        table.name,
                    "rows":
                        encoded_rows,
                }
            )

        sheets.append(
            {
                "name":
                    sheet.name,
                "tables":
                    tables,
            }
        )

    return {
        "name":
            source.name,
        "package":
            package_profile(
                source
            ),
        "sheets":
            sheets,
    }


def main():
    if len(sys.argv) != 2:
        raise RuntimeError(
            "Expected exactly one .numbers document path"
        )

    source = Path(
        sys.argv[1]
    )

    result = encode_document(
        source
    )

    json.dump(
        result,
        sys.stdout,
        separators=(
            ",",
            ":",
        ),
    )


if __name__ == "__main__":
    main()
"""#
}
