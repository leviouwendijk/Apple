import AppleNumbers
import Foundation
import TestFlows

extension AppleNumbersFlowSuite {
    static var numbersSchemaInferenceFlow: TestFlow {
        TestFlow(
            "numbers-schema-inference",
            tags: [
                "numbers",
                "snapshot",
                "schema",
                "inference",
                "determinism",
            ]
        ) {
            Step(
                "snapshot preserves position and duplicate headers"
            ) {
                let snapshot = duplicateHeaderSnapshot()

                let cells =
                    snapshot
                        .sheets[0]
                        .tables[0]
                        .rows[0]
                        .cells

                try Expect.equal(
                    cells.map(
                        \.column
                    ),
                    [
                        1,
                        2,
                    ],
                    "snapshot.duplicate-headers.columns"
                )

                try Expect.equal(
                    cells.map(
                        \.value
                    ),
                    [
                        .text("value"),
                        .text("value"),
                    ],
                    "snapshot.duplicate-headers.values"
                )
            }

            Step(
                "schema infers primitive types formats and optionality"
            ) {
                let schema = NumbersSchema(
                    inferring: inferenceSnapshot()
                )

                let clients = schema.models[0]
                let invoices = schema.models[1]

                try Expect.equal(
                    clients.fields[0].sourceName,
                    "client_id",
                    "schema.clients.client-id.name"
                )

                try Expect.equal(
                    clients.fields[0].type,
                    .number,
                    "schema.clients.client-id.type"
                )

                try Expect.false(
                    clients.fields[0].optional,
                    "schema.clients.client-id.required"
                )

                try Expect.true(
                    clients.fields[3].optional,
                    "schema.clients.note.optional"
                )

                try Expect.equal(
                    invoices.fields[2].type,
                    .number,
                    "schema.invoices.amount.type"
                )

                try Expect.equal(
                    invoices.fields[2].formats,
                    [
                        .currency,
                    ],
                    "schema.invoices.amount.formats"
                )

                try Expect.equal(
                    NumbersSchema(
                        inferring: mixedSnapshot()
                    )
                    .models[0]
                    .fields[0]
                    .type,
                    .mixed,
                    "schema.mixed.type"
                )
            }

            Step(
                "schema identifies key and cross-table relationship candidates"
            ) {
                let schema = NumbersSchema(
                    inferring: inferenceSnapshot()
                )

                let clientIdentifier =
                    NumbersFieldReference(
                        table:
                            NumbersTableReference(
                                sheet: 1,
                                table: 1
                            ),
                        column: 1
                    )

                let invoiceClientIdentifier =
                    NumbersFieldReference(
                        table:
                            NumbersTableReference(
                                sheet: 1,
                                table: 2
                            ),
                        column: 2
                    )

                try Expect.true(
                    schema.models[0]
                        .keyCandidates
                        .contains(
                            clientIdentifier
                        ),
                    "schema.key.client-id"
                )

                try Expect.equal(
                    schema.relationships.count,
                    1,
                    "schema.relationship.count"
                )

                let relationship =
                    schema.relationships[0]

                try Expect.equal(
                    relationship.source,
                    invoiceClientIdentifier,
                    "schema.relationship.source"
                )

                try Expect.equal(
                    relationship.target,
                    clientIdentifier,
                    "schema.relationship.target"
                )

                try Expect.equal(
                    relationship.cardinality,
                    .manyToOne,
                    "schema.relationship.cardinality"
                )

                try Expect.equal(
                    relationship.evidence.coverage,
                    1,
                    "schema.relationship.coverage"
                )

                try Expect.true(
                    relationship.evidence.headerMatch,
                    "schema.relationship.header-match"
                )
            }

            Step(
                "snapshot and schema are codable and deterministic"
            ) {
                let snapshot = inferenceSnapshot()

                let first = NumbersSchema(
                    inferring: snapshot
                )

                let second = NumbersSchema(
                    inferring: snapshot
                )

                try Expect.equal(
                    first,
                    second,
                    "schema.deterministic"
                )

                let encoder = JSONEncoder()

                encoder.outputFormatting = [
                    .sortedKeys,
                ]

                let snapshotData =
                    try encoder.encode(
                        snapshot
                    )

                try Expect.equal(
                    try JSONDecoder().decode(
                        NumbersSnapshot.self,
                        from: snapshotData
                    ),
                    snapshot,
                    "snapshot.codable"
                )

                let firstData =
                    try encoder.encode(
                        first
                    )

                try Expect.equal(
                    try JSONDecoder().decode(
                        NumbersSchema.self,
                        from: firstData
                    ),
                    first,
                    "schema.codable"
                )

                try Expect.equal(
                    firstData,
                    try encoder.encode(
                        second
                    ),
                    "schema.encoding.deterministic"
                )
            }
        }
    }
}

private func inferenceSnapshot()
    -> NumbersSnapshot
{
    NumbersSnapshot(
        name: "Business.numbers",
        sheets: [
            NumbersSheetSnapshot(
                index: 1,
                name: "Database",
                tables: [
                    table(
                        1,
                        "Clients",
                        columns: 4,
                        rows: [
                            row(
                                1,
                                [
                                    cell(
                                        1,
                                        1,
                                        .text(
                                            "client_id"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        2,
                                        .text(
                                            "name"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        3,
                                        .text(
                                            "active"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        4,
                                        .text(
                                            "note"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                            row(
                                2,
                                [
                                    cell(
                                        2,
                                        1,
                                        .number(
                                            100
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        2,
                                        2,
                                        .text(
                                            "Ada"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        2,
                                        3,
                                        .boolean(
                                            true
                                        ),
                                        format: .checkbox
                                    ),
                                    cell(
                                        2,
                                        4,
                                        .text(
                                            "first"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                            row(
                                3,
                                [
                                    cell(
                                        3,
                                        1,
                                        .number(
                                            101
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        3,
                                        2,
                                        .text(
                                            "Ben"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        3,
                                        3,
                                        .boolean(
                                            false
                                        ),
                                        format: .checkbox
                                    ),
                                ]
                            ),
                            row(
                                4,
                                [
                                    cell(
                                        4,
                                        1,
                                        .number(
                                            102
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        4,
                                        2,
                                        .text(
                                            "Cleo"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        4,
                                        3,
                                        .boolean(
                                            true
                                        ),
                                        format: .checkbox
                                    ),
                                    cell(
                                        4,
                                        4,
                                        .text(
                                            "third"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                        ]
                    ),
                    table(
                        2,
                        "Invoices",
                        columns: 3,
                        footerRows: 1,
                        rows: [
                            row(
                                1,
                                [
                                    cell(
                                        1,
                                        1,
                                        .text(
                                            "invoice_id"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        2,
                                        .text(
                                            "client_id"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        3,
                                        .text(
                                            "amount"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                            row(
                                2,
                                [
                                    cell(
                                        2,
                                        1,
                                        .number(
                                            9001
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        2,
                                        2,
                                        .number(
                                            100
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        2,
                                        3,
                                        .number(
                                            125
                                        ),
                                        format: .currency
                                    ),
                                ]
                            ),
                            row(
                                3,
                                [
                                    cell(
                                        3,
                                        1,
                                        .number(
                                            9002
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        3,
                                        2,
                                        .number(
                                            100
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        3,
                                        3,
                                        .number(
                                            200
                                        ),
                                        format: .currency
                                    ),
                                ]
                            ),
                            row(
                                4,
                                [
                                    cell(
                                        4,
                                        1,
                                        .number(
                                            9003
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        4,
                                        2,
                                        .number(
                                            102
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        4,
                                        3,
                                        .number(
                                            95
                                        ),
                                        format: .currency
                                    ),
                                ]
                            ),
                            row(
                                5,
                                [
                                    cell(
                                        5,
                                        3,
                                        .text(
                                            "TOTAL"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            ),
        ]
    )
}

private func duplicateHeaderSnapshot()
    -> NumbersSnapshot
{
    NumbersSnapshot(
        name: "Duplicate Headers.numbers",
        sheets: [
            NumbersSheetSnapshot(
                index: 1,
                name: "Sheet 1",
                tables: [
                    table(
                        1,
                        "Table 1",
                        columns: 2,
                        rows: [
                            row(
                                1,
                                [
                                    cell(
                                        1,
                                        1,
                                        .text(
                                            "value"
                                        ),
                                        format: .text
                                    ),
                                    cell(
                                        1,
                                        2,
                                        .text(
                                            "value"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                            row(
                                2,
                                [
                                    cell(
                                        2,
                                        1,
                                        .number(
                                            1
                                        ),
                                        format: .number
                                    ),
                                    cell(
                                        2,
                                        2,
                                        .number(
                                            2
                                        ),
                                        format: .number
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            ),
        ]
    )
}

private func mixedSnapshot()
    -> NumbersSnapshot
{
    NumbersSnapshot(
        name: "Mixed.numbers",
        sheets: [
            NumbersSheetSnapshot(
                index: 1,
                name: "Sheet 1",
                tables: [
                    table(
                        1,
                        "Mixed",
                        columns: 1,
                        rows: [
                            row(
                                1,
                                [
                                    cell(
                                        1,
                                        1,
                                        .text(
                                            "value"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                            row(
                                2,
                                [
                                    cell(
                                        2,
                                        1,
                                        .number(
                                            1
                                        ),
                                        format: .number
                                    ),
                                ]
                            ),
                            row(
                                3,
                                [
                                    cell(
                                        3,
                                        1,
                                        .text(
                                            "1"
                                        ),
                                        format: .text
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            ),
        ]
    )
}

private func table(
    _ index: Int,
    _ name: String,
    columns: Int,
    footerRows: Int = 0,
    rows: [NumbersRowSnapshot]
) -> NumbersTableSnapshot {
    NumbersTableSnapshot(
        index: index,
        name: name,
        rowCount: rows.count,
        columnCount: columns,
        headerRowCount: 1,
        headerColumnCount: 0,
        footerRowCount: footerRows,
        rows: rows
    )
}

private func row(
    _ index: Int,
    _ cells: [NumbersCellSnapshot]
) -> NumbersRowSnapshot {
    NumbersRowSnapshot(
        index: index,
        cells: cells
    )
}

private func cell(
    _ row: Int,
    _ column: Int,
    _ value: NumbersCellValue,
    format: NumbersCellFormat
) -> NumbersCellSnapshot {
    let formatted: String?

    if case .text(let text) = value {
        formatted = text
    } else {
        formatted = nil
    }

    return NumbersCellSnapshot(
        row: row,
        column: column,
        address:
            "R\(row)C\(column)",
        value: value,
        format: format,
        formatted: formatted
    )
}
