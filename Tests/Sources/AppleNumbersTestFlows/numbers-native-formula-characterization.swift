@_spi(Testing) import AppleNumbers
import TestFlows

private struct NativeFormulaReference {
    let tableName: String
    let row: Int
    let column: Int
    let key: UInt32
}

func proveNativeFormulaCharacterization(
    snapshot: NumbersSnapshot,
    storage: NumbersNativeTableStorageProfile,
    formulas: NumbersNativeFormulaProfile
) throws {
    let canonicalFormulaCount =
        snapshot.sheets
            .flatMap(
                \.tables
            )
            .flatMap(
                \.rows
            )
            .flatMap(
                \.cells
            )
            .filter {
                $0.formula != nil
            }
            .count

    var references:
        [NativeFormulaReference] = []

    for table in storage.tables {
        for tile in table.tiles {
            for row in tile.rows {
                for record in row.records {
                    guard let key =
                        record.formulaKey
                    else {
                        continue
                    }

                    references.append(
                        NativeFormulaReference(
                            tableName:
                                table.name,
                            row:
                                row.tileRowIndex
                                + 1,
                            column:
                                record.columnIndex
                                + 1,
                            key:
                                key
                        )
                    )
                }
            }
        }
    }

    try Expect.equal(
        canonicalFormulaCount,
        3,
        "native-formula.canonical-count"
    )

    try Expect.equal(
        references.count,
        canonicalFormulaCount,
        "native-formula.reference-count"
    )

    let tablesByName =
        Dictionary(
            uniqueKeysWithValues:
                formulas.tables.map {
                    (
                        $0.name,
                        $0
                    )
                }
        )

    var resolved:
        [(
            NativeFormulaReference,
            NumbersNativeFormulaProfile.Formula
        )] = []

    for reference in references {
        guard let table =
            tablesByName[
                reference.tableName
            ]
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native formula profile has no table \(reference.tableName)"
                )
        }

        let matches =
            table.formulas.filter {
                $0.key
                    == reference.key
            }

        guard matches.count == 1 else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "native formula key \(reference.key) in \(reference.tableName) resolved to \(matches.count) entries"
                )
        }

        try Expect.true(
            !matches[0]
                .nodes
                .isEmpty,
            "native-formula.\(reference.tableName).key-\(reference.key).nodes"
        )

        resolved.append(
            (
                reference,
                matches[0]
            )
        )
    }

    try Expect.equal(
        resolved.count,
        3,
        "native-formula.resolved-cell-count"
    )

    var renderedSourceLines:
        [String] = []

    for (
        reference,
        formula
    ) in resolved {
        let rendered =
            try formula.source(
                hostRow: reference.row,
                hostColumn: reference.column
            )

        guard
            let canonicalTable =
                snapshot.sheets
                    .flatMap(
                        \.tables
                    )
                    .first(
                        where: {
                            $0.name
                                == reference.tableName
                        }
                    ),
            let canonicalRow =
                canonicalTable.rows
                    .first(
                        where: {
                            $0.index
                                == reference.row
                        }
                    ),
            let canonicalCell =
                canonicalRow.cells
                    .first(
                        where: {
                            $0.column
                                == reference.column
                        }
                    ),
            let canonical =
                canonicalCell.formula
        else {
            throw AppleNumbersError
                .invalidSnapshotTransport(
                    "canonical formula source missing for \(reference.tableName) R\(reference.row)C\(reference.column)"
                )
        }

        try Expect.equal(
            rendered,
            canonical,
            "native-formula.source-parity.\(reference.tableName).R\(reference.row)C\(reference.column)"
        )

        renderedSourceLines.append(
            "\(reference.tableName) R\(reference.row)C\(reference.column): \(rendered)"
        )
    }

    renderedSourceLines.sort()

    try Expect.equal(
        renderedSourceLines,
        [
            "Invoices R2C4: =C2×2",
            "Invoices R3C4: =C3×2",
            "Invoices R4C4: =C4×2",
        ],
        "native-formula.current-fixture-rendered-sources"
    )

    print(
        "SWIFT FORMULA SOURCE"
    )

    for line in renderedSourceLines {
        print(
            "  "
            + line
        )
    }

    let uniqueKeys =
        Set(
            references.map {
                "\($0.tableName):\($0.key)"
            }
        )

    var nodeTypeCounts:
        [UInt64: Int] = [:]

    for (_, formula) in resolved {
        for node in formula.nodes {
            if let type =
                node.type
            {
                nodeTypeCounts[
                    type,
                    default:
                        0
                ] += 1
            }
        }
    }

    print(
        "SWIFT FORMULA AST"
    )

    print(
        "  canonical formula cells: "
        + String(
            canonicalFormulaCount
        )
    )

    print(
        "  referenced formula cells: "
        + String(
            references.count
        )
    )

    print(
        "  unique table/key references: "
        + String(
            uniqueKeys.count
        )
    )

    print(
        "  formula tables: "
        + formulas.tables
            .map {
                "\($0.name)=\($0.formulas.count)"
            }
            .joined(
                separator:
                    ", "
            )
    )

    print(
        "  node type histogram:"
    )

    for type in nodeTypeCounts
        .keys
        .sorted()
    {
        print(
            "    \(type): \(nodeTypeCounts[type] ?? 0)"
        )
    }

    for (
        reference,
        formula
    ) in resolved.sorted(
        by: {
            lhs,
            rhs in

            if lhs.0.tableName
                != rhs.0.tableName
            {
                return lhs.0.tableName
                    < rhs.0.tableName
            }

            if lhs.0.row
                != rhs.0.row
            {
                return lhs.0.row
                    < rhs.0.row
            }

            return lhs.0.column
                < rhs.0.column
        }
    ) {
        let hostColumn =
            formula.hostColumn.map {
                String(
                    $0
                )
            }
            ?? "nil"

        let hostRow =
            formula.hostRow.map {
                String(
                    $0
                )
            }
            ?? "nil"

        print(
            "  \(reference.tableName) R\(reference.row)C\(reference.column): key=\(reference.key) host=\(hostColumn),\(hostRow) formula-fields=\(formula.fieldSignatures.joined(separator: ","))"
        )

        for (
            index,
            node
        ) in formula.nodes.enumerated() {
            let type =
                node.type.map {
                    String(
                        $0
                    )
                }
                ?? "nil"

            let number =
                node.numberValue.map {
                    String(
                        $0
                    )
                }
                ?? "nil"

            let column =
                coordinateDescription(
                    node.column
                )

            let row =
                coordinateDescription(
                    node.row
                )

            print(
                "    node \(index): type=\(type) fields=\(node.fieldSignatures.joined(separator: ",")) number=\(number) column=\(column) row=\(row)"
            )
        }
    }
}

private func coordinateDescription(
    _ coordinate:
        NumbersNativeFormulaProfile.Coordinate?
) -> String {
    guard let coordinate else {
        return "nil"
    }

    let raw =
        coordinate.rawValue.map {
            String(
                $0
            )
        }
        ?? "nil"

    let absolute =
        coordinate.absolute.map {
            $0
            ? "true"
            : "false"
        }
        ?? "nil"

    return "raw:\(raw)/absolute:\(absolute)/fields:\(coordinate.fieldSignatures.joined(separator: ","))"
}
