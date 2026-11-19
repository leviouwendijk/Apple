import Foundation

enum NumbersNativeFormattedValueRenderer {
    static func render(
        _ value: NumbersCellValue,
        record: NumbersNativeTableStorageProfile.CellRecord,
        in table: NumbersNativeModernDataListProfile.Table
    ) throws -> String? {
        if case .empty = value {
            return nil
        }

        guard record.version == 5 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "native formatted-value rendering requires BNC-v5, found cell version \(record.version)"
                )
        }

        guard
            let formatTable =
                table.formatTable,
            formatTable.dataStoreFieldNumber == 22,
            formatTable.listType == 2
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) is missing its modern BNC FORMAT DataList for formatted-value rendering"
                )
        }

        guard let formatKey =
            record.formatKey
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) BNC-v5 cell has no format key for formatted-value rendering"
                )
        }

        let formatEntry =
            try uniqueEntry(
                key:
                    formatKey,
                in:
                    formatTable,
                context:
                    "table \(table.name) modern FORMAT"
            )

        guard
            let formatArchive =
                formatEntry.formatArchive,
            let formatType =
                formatArchive.formatType
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) modern FORMAT key \(formatKey) has no FormatStructArchive format type"
                )
        }

        if let controlKey =
            record.controlCellSpecKey
        {
            return try renderControl(
                value,
                controlKey:
                    controlKey,
                baseFormatType:
                    formatType,
                baseArchive:
                    formatArchive,
                in:
                    table
            )
        }

        switch formatType {
        case 256:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderAutomaticNumber(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 257:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderCurrency(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 258:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderPercent(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 259:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderScientific(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 260:
            guard case .text(
                let text
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "text",
                    actual:
                        value.kind.rawValue
                )
            }

            return text

        case 261:
            guard case .date(
                let date
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "date",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderDate(
                date,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 262:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderFraction(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 263:
            guard case .boolean(
                let boolean
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "boolean",
                    actual:
                        value.kind.rawValue
                )
            }

            return boolean
                ? "TRUE"
                : "FALSE"

        case 268:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderDuration(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        case 269:
            guard case .number(
                let number
            ) = value else {
                throw typeMismatch(
                    table:
                        table,
                    formatKey:
                        formatKey,
                    expected:
                        "number",
                    actual:
                        value.kind.rawValue
                )
            }

            return try renderNumeralSystem(
                number,
                archive:
                    formatArchive,
                tableName:
                    table.name,
                formatKey:
                    formatKey
            )

        default:
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) modern FORMAT key \(formatKey) has uncharacterized formatted-value type \(formatType)"
                )
        }
    }

    private static func renderControl(
        _ value: NumbersCellValue,
        controlKey: UInt32,
        baseFormatType: UInt64,
        baseArchive: NumbersNativeModernDataListProfile.FormatArchive,
        in table: NumbersNativeModernDataListProfile.Table
    ) throws -> String {
        guard
            let controlTable =
                table.controlCellSpecTable,
            controlTable.dataStoreFieldNumber == 21,
            controlTable.listType == 12
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) cell references control key \(controlKey) without a modern CONTROL_CELL_SPEC DataList"
                )
        }

        let controlEntry =
            try uniqueEntry(
                key:
                    controlKey,
                in:
                    controlTable,
                context:
                    "table \(table.name) modern CONTROL_CELL_SPEC"
            )

        guard
            let cellSpec =
                controlEntry.cellSpecArchive,
            let interactionType =
                cellSpec.interactionType
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) CONTROL_CELL_SPEC key \(controlKey) has no interaction type"
                )
        }

        switch interactionType {
        case 4,
             5:
            guard
                baseFormatType == 256,
                case .number(
                    let number
                ) = value
            else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) slider/stepper control key \(controlKey) has uncharacterized base format/value"
                    )
            }

            return try renderAutomaticNumber(
                number,
                archive:
                    baseArchive,
                tableName:
                    table.name,
                formatKey:
                    controlKey
            )

        case 6:
            guard case .number(
                let number
            ) = value else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) rating control key \(controlKey) expected number value, found \(value.kind.rawValue)"
                    )
            }

            return try renderRating(
                number,
                tableName:
                    table.name,
                controlKey:
                    controlKey
            )

        case 7:
            guard case .text(
                let text
            ) = value else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) pop-up control key \(controlKey) expected text value, found \(value.kind.rawValue)"
                    )
            }

            return text

        case 8:
            guard case .boolean(
                let boolean
            ) = value else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(table.name) checkbox control key \(controlKey) expected boolean value, found \(value.kind.rawValue)"
                    )
            }

            return boolean
                ? "TRUE"
                : "FALSE"

        default:
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(table.name) CONTROL_CELL_SPEC key \(controlKey) interaction \(interactionType) has uncharacterized formatted-value rendering with base format type \(baseFormatType)"
                )
        }
    }

    private static func renderAutomaticNumber(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        let formatter =
            NumberFormatter()

        formatter.locale =
            Locale.current

        formatter.numberStyle =
            .decimal

        formatter.usesGroupingSeparator =
            archive.showThousandsSeparator
            ?? false

        formatter.minimumFractionDigits =
            0

        if let decimalPlaces =
            archive.decimalPlaces,
           decimalPlaces != 253
        {
            guard decimalPlaces <= 38 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(tableName) FORMAT key \(formatKey) decimal places \(decimalPlaces) exceed characterized range"
                    )
            }

            formatter.maximumFractionDigits =
                Int(
                    decimalPlaces
                )
        } else {
            formatter.maximumFractionDigits =
                38
        }

        formatter.generatesDecimalNumbers =
            true

        guard let result =
            formatter.string(
                from:
                    NSDecimalNumber(
                        decimal:
                            value
                    )
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) FORMAT key \(formatKey) could not render automatic number"
                )
        }

        return result
    }

    private static func renderCurrency(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard
            let currencyCode =
                archive.currencyCode,
            !currencyCode.isEmpty
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) currency FORMAT key \(formatKey) has no currency code"
                )
        }

        guard archive.useAccountingStyle != true else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) currency FORMAT key \(formatKey) uses uncharacterized accounting style"
                )
        }

        let decimalPlaces =
            archive.decimalPlaces
            ?? 2

        guard decimalPlaces <= 38 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) currency FORMAT key \(formatKey) decimal places \(decimalPlaces) exceed characterized range"
                )
        }

        let formatter =
            NumberFormatter()

        formatter.locale =
            Locale.current

        formatter.numberStyle =
            .currency

        formatter.currencyCode =
            currencyCode

        formatter.usesGroupingSeparator =
            archive.showThousandsSeparator
            ?? false

        formatter.minimumFractionDigits =
            Int(
                decimalPlaces
            )

        formatter.maximumFractionDigits =
            Int(
                decimalPlaces
            )

        formatter.generatesDecimalNumbers =
            true

        guard let result =
            formatter.string(
                from:
                    NSDecimalNumber(
                        decimal:
                            value
                    )
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) FORMAT key \(formatKey) could not render currency"
                )
        }

        return result
    }

    private static func renderPercent(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        let percentage =
            value
            * Decimal(
                100
            )

        let rendered =
            try renderAutomaticNumber(
                percentage,
                archive:
                    archive,
                tableName:
                    tableName,
                formatKey:
                    formatKey
            )

        return rendered
            + "%"
    }

    private static func renderScientific(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard
            archive.decimalPlaces == nil
            || archive.decimalPlaces == 253
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) scientific FORMAT key \(formatKey) has uncharacterized fixed decimal places"
                )
        }

        let formatter =
            NumberFormatter()

        formatter.locale =
            Locale.current

        formatter.numberStyle =
            .scientific

        formatter.usesGroupingSeparator =
            false

        formatter.exponentSymbol =
            "E"

        formatter.positiveFormat =
            "0.############################E+00"

        formatter.negativeFormat =
            "-0.############################E+00"

        formatter.generatesDecimalNumbers =
            true

        guard let result =
            formatter.string(
                from:
                    NSDecimalNumber(
                        decimal:
                            value
                    )
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) scientific FORMAT key \(formatKey) could not render value"
                )
        }

        return result
    }

    private static func renderDate(
        _ value: Date,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard
            let dateTimeFormat =
                archive.dateTimeFormat,
            !dateTimeFormat.isEmpty
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) date FORMAT key \(formatKey) has no characterized date-time pattern"
                )
        }

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale.current

        formatter.timeZone =
            TimeZone.current

        formatter.dateFormat =
            dateTimeFormat

        return formatter.string(
            from:
                value
        )
    }

    private static func renderFraction(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard archive.fractionAccuracy == 4_294_967_293 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) has uncharacterized accuracy \(String(describing: archive.fractionAccuracy))"
                )
        }

        let (
            numerator,
            denominator
        ) =
            try exactFiniteDecimalFraction(
                value,
                tableName:
                    tableName,
                formatKey:
                    formatKey
            )

        guard numerator.magnitude < UInt64(denominator) else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) mixed-number rendering is not characterized yet"
                )
        }

        return String(
            numerator
        )
        + "/"
        + String(
            denominator
        )
    }

    private static func renderDuration(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard
            archive.durationStyle == 1,
            archive.useAutomaticDurationUnits == true
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) duration FORMAT key \(formatKey) has uncharacterized duration settings"
                )
        }

        guard let rawSeconds =
            exactInt64(
                value
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) duration FORMAT key \(formatKey) has non-integral seconds"
                )
        }

        let negative =
            rawSeconds < 0

        var remaining =
            rawSeconds.magnitude

        let days =
            remaining
            / 86_400

        remaining %=
            86_400

        let hours =
            remaining
            / 3_600

        remaining %=
            3_600

        let minutes =
            remaining
            / 60

        let seconds =
            remaining
            % 60

        var parts:
            [String] = []

        if days > 0 {
            parts.append(
                String(
                    days
                )
                + "d"
            )
        }

        if hours > 0 {
            parts.append(
                String(
                    hours
                )
                + "h"
            )
        }

        if minutes > 0 {
            parts.append(
                String(
                    minutes
                )
                + "m"
            )
        }

        if seconds > 0 {
            parts.append(
                String(
                    seconds
                )
                + "s"
            )
        }

        if parts.isEmpty {
            parts.append(
                "0s"
            )
        }

        let result =
            parts.joined(
                separator:
                    " "
            )

        return negative
            ? "-"
                + result
            : result
    }

    private static func renderRating(
        _ value: Decimal,
        tableName: String,
        controlKey: UInt32
    ) throws -> String {
        guard let integer =
            exactInt64(
                value
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) rating control key \(controlKey) has a non-integral value"
                )
        }

        return String(
            integer
        )
        + " ★"
    }

    private static func renderNumeralSystem(
        _ value: Decimal,
        archive: NumbersNativeModernDataListProfile.FormatArchive,
        tableName: String,
        formatKey: UInt32
    ) throws -> String {
        guard archive.base == 10 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) numeral-system FORMAT key \(formatKey) base \(String(describing: archive.base)) is not characterized yet"
                )
        }

        guard archive.basePlaces == 0 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) numeral-system FORMAT key \(formatKey) fractional base places are not characterized yet"
                )
        }

        if
            value < 0,
            archive.baseUseMinusSign != true
        {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) numeral-system FORMAT key \(formatKey) negative non-minus-sign rendering is not characterized yet"
                )
        }

        var source =
            value

        var rounded =
            Decimal()

        NSDecimalRound(
            &rounded,
            &source,
            0,
            .plain
        )

        return NSDecimalNumber(
            decimal:
                rounded
        )
        .stringValue
    }

    private static func exactFiniteDecimalFraction(
        _ value: Decimal,
        tableName: String,
        formatKey: UInt32
    ) throws -> (
        Int64,
        UInt64
    ) {
        let raw =
            NSDecimalNumber(
                decimal:
                    value
            )
            .stringValue

        guard
            !raw.contains("e"),
            !raw.contains("E")
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) scientific decimal storage is not characterized"
                )
        }

        let negative =
            raw.hasPrefix(
                "-"
            )

        let unsigned =
            negative
            ? String(
                raw.dropFirst()
            )
            : raw

        let parts =
            unsigned.split(
                separator:
                    ".",
                omittingEmptySubsequences:
                    false
            )

        guard
            parts.count == 1
            || parts.count == 2
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) has invalid decimal lexeme \(raw)"
                )
        }

        let whole =
            String(
                parts[0]
            )

        let fractional =
            parts.count == 2
            ? String(
                parts[1]
            )
            : ""

        guard fractional.count <= 18 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) exceeds characterized decimal precision"
                )
        }

        let digits =
            whole
            + fractional

        guard var numerator =
            Int64(
                digits
            )
        else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "table \(tableName) fraction FORMAT key \(formatKey) cannot fit numerator in Int64"
                )
        }

        if negative {
            numerator =
                -numerator
        }

        var denominator:
            UInt64 = 1

        for _ in 0..<fractional.count {
            let (
                multiplied,
                overflow
            ) =
                denominator.multipliedReportingOverflow(
                    by:
                        10
                )

            guard !overflow else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "table \(tableName) fraction FORMAT key \(formatKey) denominator overflow"
                    )
            }

            denominator =
                multiplied
        }

        let divisor =
            greatestCommonDivisor(
                numerator.magnitude,
                denominator
            )

        numerator /=
            Int64(
                divisor
            )

        denominator /=
            divisor

        return (
            numerator,
            denominator
        )
    }

    private static func greatestCommonDivisor(
        _ lhs: UInt64,
        _ rhs: UInt64
    ) -> UInt64 {
        var left =
            lhs

        var right =
            rhs

        while right != 0 {
            let remainder =
                left
                % right

            left =
                right

            right =
                remainder
        }

        return max(
            left,
            1
        )
    }

    private static func exactInt64(
        _ value: Decimal
    ) -> Int64? {
        Int64(
            NSDecimalNumber(
                decimal:
                    value
            )
            .stringValue
        )
    }

    private static func typeMismatch(
        table: NumbersNativeModernDataListProfile.Table,
        formatKey: UInt32,
        expected: String,
        actual: String
    ) -> NumbersObjectGraphError {
        .invalidObjectGraph(
            "table \(table.name) FORMAT key \(formatKey) expected \(expected) value for formatted rendering, found \(actual)"
        )
    }

    private static func uniqueEntry(
        key: UInt32,
        in list: NumbersNativeModernDataListProfile.DataList,
        context: String
    ) throws -> NumbersNativeModernDataListProfile.Entry {
        let matches =
            list.entries.filter {
                $0.key == key
            }

        guard matches.count == 1 else {
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context) key \(key) resolved to \(matches.count) entries"
                )
        }

        return matches[0]
    }
}
