import Foundation

public struct NumbersCellFormat:
    RawRepresentable,
    Codable,
    Hashable,
    Sendable,
    Comparable
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public static let automatic = Self(
        rawValue: "automatic"
    )

    public static let checkbox = Self(
        rawValue: "checkbox"
    )

    public static let currency = Self(
        rawValue: "currency"
    )

    public static let dateAndTime = Self(
        rawValue: "date_and_time"
    )

    public static let duration = Self(
        rawValue: "duration"
    )

    public static let fraction = Self(
        rawValue: "fraction"
    )

    public static let number = Self(
        rawValue: "number"
    )

    public static let numeralSystem = Self(
        rawValue: "numeral_system"
    )

    public static let percent = Self(
        rawValue: "percent"
    )

    public static let popUpMenu = Self(
        rawValue: "pop_up_menu"
    )

    public static let rating = Self(
        rawValue: "rating"
    )

    public static let scientific = Self(
        rawValue: "scientific"
    )

    public static let slider = Self(
        rawValue: "slider"
    )

    public static let stepper = Self(
        rawValue: "stepper"
    )

    public static let text = Self(
        rawValue: "text"
    )

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum NumbersCellValue:
    Codable,
    Hashable,
    Sendable
{
    public enum Kind:
        String,
        Codable,
        Hashable,
        Sendable
    {
        case empty
        case text
        case number
        case boolean
        case date
    }

    case empty
    case text(String)
    case number(Decimal)
    case boolean(Bool)
    case date(Date)

    public var kind: Kind {
        switch self {
        case .empty:
            .empty

        case .text:
            .text

        case .number:
            .number

        case .boolean:
            .boolean

        case .date:
            .date
        }
    }

    public var isEmpty: Bool {
        if case .empty = self {
            true
        } else {
            false
        }
    }
}
