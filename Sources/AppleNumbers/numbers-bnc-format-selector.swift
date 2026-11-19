@_spi(Testing)
public struct NumbersNativeBNCFormatReference:
    Equatable,
    Sendable
{
    public let family:
        NumbersNativeCellFormatFamily

    public let key:
        UInt32

    public init(
        family: NumbersNativeCellFormatFamily,
        key: UInt32
    ) {
        self.family = family
        self.key = key
    }
}

@_spi(Testing)
public enum NumbersNativeBNCFormatSelector {
    public static func select(
        _ references:
            [NumbersNativeBNCFormatReference],
        suggestedFormatKind: UInt32?,
        cellType: UInt8,
        controlCellSpecKey: UInt32?,
        context: String
    ) throws -> NumbersNativeBNCFormatReference? {
        guard references.count > 1 else {
            return references.first
        }

        if let suggestedFormatKind {
            let family =
                try family(
                    for:
                        suggestedFormatKind,
                    context:
                        context
                )

            let matches =
                references.filter {
                    $0.family == family
                }

            guard matches.count == 1 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): BNC-v5 suggested format kind \(suggestedFormatKind) selects \(family.rawValue), but \(matches.count) matching specialized references were present"
                    )
            }

            return matches[0]
        }

        if
            cellType == 0,
            controlCellSpecKey != nil
        {
            let matches =
                references.filter {
                    $0.family == .text
                }

            guard matches.count == 1 else {
                throw NumbersObjectGraphError
                    .invalidObjectGraph(
                        "\(context): BNC-v5 empty control-backed cell has \(references.count) specialized references but \(matches.count) text references"
                    )
            }

            return matches[0]
        }

        throw NumbersObjectGraphError
            .invalidObjectGraph(
                "\(context): BNC-v5 cell contains \(references.count) simultaneous specialized format references without a characterized selector"
            )
    }

    private static func family(
        for suggestedFormatKind: UInt32,
        context: String
    ) throws -> NumbersNativeCellFormatFamily {
        switch suggestedFormatKind {
        case 1:
            return .number

        case 2:
            return .currency

        case 3:
            return .date

        case 4:
            return .duration

        case 5:
            return .text

        case 6:
            return .boolean

        default:
            throw NumbersObjectGraphError
                .invalidObjectGraph(
                    "\(context): BNC-v5 suggested format kind \(suggestedFormatKind) is not characterized"
                )
        }
    }
}
