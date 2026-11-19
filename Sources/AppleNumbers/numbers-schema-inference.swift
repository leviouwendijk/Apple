import Foundation

public extension NumbersSchema {
    init(
        inferring snapshot: NumbersSnapshot
    ) {
        let result = Self.infer(
            snapshot
        )

        self.init(
            models: result.models,
            relationships: result.relationships
        )
    }
}

private extension NumbersSchema {
    struct FieldObservation {
        let schema: NumbersFieldSchema
        let values: Set<NumbersCellValue>
    }

    struct InferenceResult {
        let models: [NumbersModelSchema]
        let relationships: [NumbersRelationshipCandidate]
    }

    static func infer(
        _ snapshot: NumbersSnapshot
    ) -> InferenceResult {
        var models: [NumbersModelSchema] = []

        var observations: [
            NumbersFieldReference: FieldObservation
        ] = [:]

        for sheet in snapshot.sheets {
            for table in sheet.tables {
                let tableReference = NumbersTableReference(
                    sheet: sheet.index,
                    table: table.index
                )

                let finalBodyRow = max(
                    table.headerRowCount,
                    table.rowCount - table.footerRowCount
                )

                let bodyRows = table.rows.filter {
                    $0.index > table.headerRowCount
                    && $0.index <= finalBodyRow
                }

                var fields: [NumbersFieldSchema] = []
                var keys: [NumbersFieldReference] = []

                guard table.columnCount > 0 else {
                    models.append(
                        NumbersModelSchema(
                            source: tableReference,
                            name: modelName(
                                table
                            ),
                            fields: [],
                            keyCandidates: []
                        )
                    )

                    continue
                }

                for column in 1...table.columnCount {
                    let reference = NumbersFieldReference(
                        table: tableReference,
                        column: column
                    )

                    let cells = bodyRows.map {
                        cell(
                            in: $0,
                            column: column
                        )
                    }

                    let nonEmpty = cells.filter {
                        !$0.value.isEmpty
                    }

                    let values = Set(
                        nonEmpty.map(
                            \.value
                        )
                    )

                    let schema = NumbersFieldSchema(
                        source: reference,
                        sourceName:
                            headerName(
                                in: table,
                                column: column
                            ),
                        type:
                            fieldType(
                                values:
                                    nonEmpty.map(
                                        \.value
                                    )
                            ),
                        formats:
                            Array(
                                Set(
                                    nonEmpty.map(
                                        \.format
                                    )
                                )
                            )
                            .sorted(),
                        optional:
                            bodyRows.isEmpty
                            || nonEmpty.count != bodyRows.count,
                        rowCount: bodyRows.count,
                        nonEmptyCount: nonEmpty.count,
                        distinctCount: values.count
                    )

                    fields.append(
                        schema
                    )

                    observations[reference] =
                        FieldObservation(
                            schema: schema,
                            values: values
                        )

                    if isKeyCandidate(
                        schema
                    ) {
                        keys.append(
                            reference
                        )
                    }
                }

                models.append(
                    NumbersModelSchema(
                        source: tableReference,
                        name: modelName(
                            table
                        ),
                        fields: fields,
                        keyCandidates: keys
                    )
                )
            }
        }

        return InferenceResult(
            models: models,
            relationships:
                relationships(
                    models: models,
                    observations: observations
                )
        )
    }

    static func relationships(
        models: [NumbersModelSchema],
        observations: [
            NumbersFieldReference: FieldObservation
        ]
    ) -> [NumbersRelationshipCandidate] {
        let targets = models.flatMap {
            model in

            model.keyCandidates.compactMap {
                reference -> FieldObservation? in

                observations[reference]
            }
        }

        var result: [NumbersRelationshipCandidate] = []

        for model in models {
            for field in model.fields {
                guard
                    field.nonEmptyCount >= 2,
                    field.distinctCount >= 2,
                    field.type != .empty,
                    field.type != .mixed,
                    let source =
                        observations[
                            field.source
                        ]
                else {
                    continue
                }

                for target in targets {
                    guard
                        target.schema.source.table
                            != field.source.table,
                        target.schema.type == field.type,
                        target.schema.distinctCount >= 3,
                        source.values.isSubset(
                            of: target.values
                        )
                    else {
                        continue
                    }

                    let matched = source.values
                        .intersection(
                            target.values
                        )
                        .count

                    let coverage =
                        Double(
                            matched
                        )
                        / Double(
                            source.values.count
                        )

                    result.append(
                        NumbersRelationshipCandidate(
                            source:
                                field.source,
                            target:
                                target.schema.source,
                            cardinality:
                                field.nonEmptyCount
                                == field.distinctCount
                                ? .oneToOne
                                : .manyToOne,
                            evidence:
                                NumbersRelationshipEvidence(
                                    sourceNonEmptyCount:
                                        field.nonEmptyCount,
                                    sourceDistinctCount:
                                        field.distinctCount,
                                    matchedDistinctCount:
                                        matched,
                                    coverage:
                                        coverage,
                                    headerMatch:
                                        headersMatch(
                                            field.sourceName,
                                            target
                                                .schema
                                                .sourceName
                                        )
                                )
                        )
                    )
                }
            }
        }

        return result.sorted {
            lhs,
            rhs in

            if lhs.source != rhs.source {
                return lhs.source < rhs.source
            }

            return lhs.target < rhs.target
        }
    }

    static func isKeyCandidate(
        _ field: NumbersFieldSchema
    ) -> Bool {
        field.rowCount >= 2
        && field.nonEmptyCount == field.rowCount
        && field.distinctCount == field.nonEmptyCount
        && field.type != .empty
        && field.type != .mixed
    }

    static func fieldType(
        values: [NumbersCellValue]
    ) -> NumbersFieldType {
        let kinds = Set(
            values.map(
                \.kind
            )
        )

        guard let kind = kinds.first else {
            return .empty
        }

        guard kinds.count == 1 else {
            return .mixed
        }

        switch kind {
        case .empty:
            return .empty

        case .text:
            return .text

        case .number:
            return .number

        case .boolean:
            return .boolean

        case .date:
            return .date
        }
    }

    static func headerName(
        in table: NumbersTableSnapshot,
        column: Int
    ) -> String? {
        guard table.headerRowCount > 0 else {
            return nil
        }

        return table.rows
            .filter {
                $0.index <= table.headerRowCount
            }
            .sorted {
                $0.index > $1.index
            }
            .compactMap {
                row -> String? in

                guard let cell =
                    row.cells.first(
                        where: {
                            $0.column == column
                        }
                    )
                else {
                    return nil
                }

                if let formatted = nonEmpty(
                    cell.formatted
                ) {
                    return formatted
                }

                if case .text(let text) = cell.value {
                    return nonEmpty(
                        text
                    )
                }

                return nil
            }
            .first
    }

    static func headersMatch(
        _ lhs: String?,
        _ rhs: String?
    ) -> Bool {
        guard
            let lhs = normalizedHeader(
                lhs
            ),
            let rhs = normalizedHeader(
                rhs
            )
        else {
            return false
        }

        return lhs == rhs
    }

    static func normalizedHeader(
        _ value: String?
    ) -> String? {
        guard let value = nonEmpty(
            value
        ) else {
            return nil
        }

        let normalized = value
            .lowercased()
            .unicodeScalars
            .filter {
                CharacterSet.alphanumerics.contains(
                    $0
                )
            }
            .map(
                String.init
            )
            .joined()

        return normalized.isEmpty
            ? nil
            : normalized
    }

    static func nonEmpty(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        return value.isEmpty
            ? nil
            : value
    }

    static func cell(
        in row: NumbersRowSnapshot,
        column: Int
    ) -> NumbersCellSnapshot {
        row.cells.first(
            where: {
                $0.column == column
            }
        )
        ?? NumbersCellSnapshot(
            row: row.index,
            column: column,
            address:
                "R\(row.index)C\(column)",
            value: .empty,
            format: .automatic
        )
    }

    static func modelName(
        _ table: NumbersTableSnapshot
    ) -> String {
        table.name.isEmpty
            ? "Table \(table.index)"
            : table.name
    }
}
