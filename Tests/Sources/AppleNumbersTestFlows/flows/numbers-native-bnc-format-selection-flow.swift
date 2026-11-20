@_spi(Testing) import AppleNumbers
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersNativeBNCFormatSelectionFlow:
        TestFlow
    {
        TestFlow(
            "numbers-native-bnc-format-selection",
            tags: [
                "numbers",
                "native",
                "bnc-v5",
                "format",
                "regression",
            ]
        ) {
            Step(
                "BNC-v5 suggested format kinds select the characterized specialized family"
            ) {
                typealias Reference =
                    NumbersNativeBNCFormatReference

                let references: [Reference] = [
                    Reference(
                        family: .number,
                        key: 11
                    ),
                    Reference(
                        family: .currency,
                        key: 12
                    ),
                    Reference(
                        family: .date,
                        key: 13
                    ),
                    Reference(
                        family: .duration,
                        key: 14
                    ),
                    Reference(
                        family: .text,
                        key: 15
                    ),
                    Reference(
                        family: .boolean,
                        key: 16
                    ),
                ]

                let cases:
                    [
                        (
                            kind: UInt32,
                            family:
                                NumbersNativeCellFormatFamily,
                            key: UInt32
                        )
                    ] = [
                        (
                            1,
                            .number,
                            11
                        ),
                        (
                            2,
                            .currency,
                            12
                        ),
                        (
                            3,
                            .date,
                            13
                        ),
                        (
                            4,
                            .duration,
                            14
                        ),
                        (
                            5,
                            .text,
                            15
                        ),
                        (
                            6,
                            .boolean,
                            16
                        ),
                    ]

                for item in cases {
                    let selected =
                        try NumbersNativeBNCFormatSelector
                            .select(
                                references,
                                suggestedFormatKind:
                                    item.kind,
                                cellType:
                                    0,
                                controlCellSpecKey:
                                    nil,
                                context:
                                    "synthetic suggested selector"
                            )

                    try Expect.equal(
                        selected,
                        Reference(
                            family:
                                item.family,
                            key:
                                item.key
                        ),
                        "bnc.suggested-kind-\(item.kind)"
                    )
                }
            }

            Step(
                "BNC-v5 empty control-backed collisions select the characterized text candidate"
            ) {
                typealias Reference =
                    NumbersNativeBNCFormatReference

                let selected =
                    try NumbersNativeBNCFormatSelector
                        .select(
                            [
                                Reference(
                                    family: .number,
                                    key: 21
                                ),
                                Reference(
                                    family: .currency,
                                    key: 22
                                ),
                                Reference(
                                    family: .text,
                                    key: 23
                                ),
                            ],
                            suggestedFormatKind:
                                nil,
                            cellType:
                                0,
                            controlCellSpecKey:
                                99,
                            context:
                                "synthetic pop-up selector"
                        )

                try Expect.equal(
                    selected,
                    Reference(
                        family: .text,
                        key: 23
                    ),
                    "bnc.empty-control-text"
                )

                let twoFamilySelected =
                    try NumbersNativeBNCFormatSelector
                        .select(
                            [
                                Reference(
                                    family: .currency,
                                    key: 31
                                ),
                                Reference(
                                    family: .text,
                                    key: 32
                                ),
                            ],
                            suggestedFormatKind:
                                nil,
                            cellType:
                                0,
                            controlCellSpecKey:
                                100,
                            context:
                                "synthetic two-family pop-up selector"
                        )

                try Expect.equal(
                    twoFamilySelected,
                    Reference(
                        family: .text,
                        key: 32
                    ),
                    "bnc.empty-control-two-family-text"
                )
            }

            Step(
                "BNC-v5 uncharacterized ambiguous shapes remain fail-closed"
            ) {
                typealias Reference =
                    NumbersNativeBNCFormatReference

                var nonControlFailed =
                    false

                do {
                    _ =
                        try NumbersNativeBNCFormatSelector
                            .select(
                                [
                                    Reference(
                                        family: .currency,
                                        key: 41
                                    ),
                                    Reference(
                                        family: .number,
                                        key: 42
                                    ),
                                ],
                                suggestedFormatKind:
                                    nil,
                                cellType:
                                    0,
                                controlCellSpecKey:
                                    nil,
                                context:
                                    "synthetic unresolved empty"
                            )
                } catch {
                    nonControlFailed =
                        true
                }

                try Expect.equal(
                    nonControlFailed,
                    true,
                    "bnc.unsuggested-non-control-fails"
                )

                var nonEmptyControlFailed =
                    false

                do {
                    _ =
                        try NumbersNativeBNCFormatSelector
                            .select(
                                [
                                    Reference(
                                        family: .number,
                                        key: 51
                                    ),
                                    Reference(
                                        family: .text,
                                        key: 52
                                    ),
                                ],
                                suggestedFormatKind:
                                    nil,
                                cellType:
                                    3,
                                controlCellSpecKey:
                                    101,
                                context:
                                    "synthetic non-empty control"
                            )
                } catch {
                    nonEmptyControlFailed =
                        true
                }

                try Expect.equal(
                    nonEmptyControlFailed,
                    true,
                    "bnc.unsuggested-non-empty-control-fails"
                )

                var absentSuggestedFamilyFailed =
                    false

                do {
                    _ =
                        try NumbersNativeBNCFormatSelector
                            .select(
                                [
                                    Reference(
                                        family: .number,
                                        key: 61
                                    ),
                                    Reference(
                                        family: .currency,
                                        key: 62
                                    ),
                                ],
                                suggestedFormatKind:
                                    5,
                                cellType:
                                    3,
                                controlCellSpecKey:
                                    nil,
                                context:
                                    "synthetic absent suggested family"
                            )
                } catch {
                    absentSuggestedFamilyFailed =
                        true
                }

                try Expect.equal(
                    absentSuggestedFamilyFailed,
                    true,
                    "bnc.absent-suggested-family-fails"
                )

                var unknownSuggestedKindFailed =
                    false

                do {
                    _ =
                        try NumbersNativeBNCFormatSelector
                            .select(
                                [
                                    Reference(
                                        family: .number,
                                        key: 71
                                    ),
                                    Reference(
                                        family: .currency,
                                        key: 72
                                    ),
                                ],
                                suggestedFormatKind:
                                    99,
                                cellType:
                                    3,
                                controlCellSpecKey:
                                    nil,
                                context:
                                    "synthetic unknown suggested kind"
                            )
                } catch {
                    unknownSuggestedKindFailed =
                        true
                }

                try Expect.equal(
                    unknownSuggestedKindFailed,
                    true,
                    "bnc.unknown-suggested-kind-fails"
                )
            }

            Step(
                "BNC-v5 zero and single format references preserve prior behavior"
            ) {
                typealias Reference =
                    NumbersNativeBNCFormatReference

                let none =
                    try NumbersNativeBNCFormatSelector
                        .select(
                            [],
                            suggestedFormatKind:
                                nil,
                            cellType:
                                0,
                            controlCellSpecKey:
                                nil,
                            context:
                                "synthetic no reference"
                        )

                try Expect.equal(
                    none,
                    nil,
                    "bnc.no-reference"
                )

                let reference =
                    Reference(
                        family: .date,
                        key: 81
                    )

                let one =
                    try NumbersNativeBNCFormatSelector
                        .select(
                            [
                                reference,
                            ],
                            suggestedFormatKind:
                                nil,
                            cellType:
                                5,
                            controlCellSpecKey:
                                nil,
                            context:
                                "synthetic single reference"
                        )

                try Expect.equal(
                    one,
                    reference,
                    "bnc.single-reference"
                )
            }
        }
    }
}
