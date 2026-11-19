enum NumbersSnapshotScript {
    static let source = #"""
function safeProperty(read) {
    try {
        const value = read();

        return value === undefined
            ? null
            : value;
    } catch (_) {
        return null;
    }
}

function normalizeFormat(value) {
    if (
        value === null
        || value === undefined
    ) {
        return "automatic";
    }

    const raw = String(value)
        .trim()
        .toLowerCase();

    switch (raw) {
    case "date and time":
        return "date_and_time";

    case "numeral system":
        return "numeral_system";

    case "pop up menu":
    case "pop-up menu":
        return "pop_up_menu";

    default:
        return raw
            .replace(/-/g, "_")
            .replace(/\s+/g, "_");
    }
}

function cellValue(value) {
    if (
        value === null
        || value === undefined
    ) {
        return {
            kind: "empty"
        };
    }

    if (
        value instanceof Date
        || Object.prototype.toString.call(value) === "[object Date]"
    ) {
        return {
            kind: "date",
            date: value.toISOString()
        };
    }

    switch (typeof value) {
    case "string":
        return {
            kind: "text",
            text: value
        };

    case "number":
        if (!Number.isFinite(value)) {
            return {
                kind: "unsupported",
                text: String(value)
            };
        }

        return {
            kind: "number",
            number: String(value)
        };

    case "boolean":
        return {
            kind: "boolean",
            boolean: value
        };

    default:
        return {
            kind: "unsupported",
            text: String(value)
        };
    }
}

function snapshotCellValues(
    rawValue,
    rawFormat,
    formatted,
    formula,
    address,
    rowIndex,
    columnIndex
) {
    return {
        row: rowIndex,
        column: columnIndex,
        address:
            address === null
            || address === undefined
                ? `R${rowIndex}C${columnIndex}`
                : String(address),
        value: cellValue(
            rawValue
        ),
        format: normalizeFormat(
            rawFormat
        ),
        formula:
            formula === null
            || formula === undefined
            || String(formula).trim().length === 0
                ? null
                : String(formula),
        formatted:
            formatted === null
            || formatted === undefined
                ? null
                : String(formatted)
    };
}

function snapshotCell(
    cell,
    rowIndex,
    columnIndex
) {
    const rawValue = safeProperty(
        () => cell.value()
    );

    const rawFormat = safeProperty(
        () => cell.format()
    );

    const formatted = safeProperty(
        () => cell.formattedValue()
    );

    const formula = safeProperty(
        () => cell.formula()
    );

    const address = safeProperty(
        () => cell.name()
    );

    return snapshotCellValues(
        rawValue,
        rawFormat,
        formatted,
        formula,
        address,
        rowIndex,
        columnIndex
    );
}

function snapshotRow(
    row,
    rowIndex
) {
    const cells = row.cells();

    return {
        index: rowIndex,
        cells: cells.map(
            (cell, columnOffset) =>
                snapshotCell(
                    cell,
                    rowIndex,
                    columnOffset + 1
                )
        )
    };
}

function propertyMatrix(
    value,
    rowCount,
    columnCount
) {
    if (!Array.isArray(value)) {
        return null;
    }

    const nested =
        value.length === rowCount
        && value.every(
            row =>
                Array.isArray(row)
                && row.length === columnCount
        );

    if (nested) {
        return value;
    }

    if (
        value.length
        !== rowCount * columnCount
    ) {
        return null;
    }

    const result = [];

    for (
        let rowOffset = 0;
        rowOffset < rowCount;
        rowOffset += 1
    ) {
        const start =
            rowOffset * columnCount;

        result.push(
            value.slice(
                start,
                start + columnCount
            )
        );
    }

    return result;
}

function snapshotRowsBulk(
    table,
    rowCount,
    columnCount
) {
    const rawValues =
        propertyMatrix(
            safeProperty(
                () =>
                    table.rows.cells.value()
            ),
            rowCount,
            columnCount
        );

    const rawFormats =
        propertyMatrix(
            safeProperty(
                () =>
                    table.rows.cells.format()
            ),
            rowCount,
            columnCount
        );

    const formattedValues =
        propertyMatrix(
            safeProperty(
                () =>
                    table.rows.cells.formattedValue()
            ),
            rowCount,
            columnCount
        );

    const formulas =
        propertyMatrix(
            safeProperty(
                () =>
                    table.rows.cells.formula()
            ),
            rowCount,
            columnCount
        );

    const addresses =
        propertyMatrix(
            safeProperty(
                () =>
                    table.rows.cells.name()
            ),
            rowCount,
            columnCount
        );

    if (
        rawValues === null
        || rawFormats === null
        || formattedValues === null
        || formulas === null
        || addresses === null
    ) {
        return null;
    }

    const result = [];

    for (
        let rowOffset = 0;
        rowOffset < rowCount;
        rowOffset += 1
    ) {
        const rowIndex =
            rowOffset + 1;

        const cells = [];

        for (
            let columnOffset = 0;
            columnOffset < columnCount;
            columnOffset += 1
        ) {
            cells.push(
                snapshotCellValues(
                    rawValues[
                        rowOffset
                    ][
                        columnOffset
                    ],
                    rawFormats[
                        rowOffset
                    ][
                        columnOffset
                    ],
                    formattedValues[
                        rowOffset
                    ][
                        columnOffset
                    ],
                    formulas[
                        rowOffset
                    ][
                        columnOffset
                    ],
                    addresses[
                        rowOffset
                    ][
                        columnOffset
                    ],
                    rowIndex,
                    columnOffset + 1
                )
            );
        }

        result.push(
            {
                index: rowIndex,
                cells: cells
            }
        );
    }

    return result;
}

function snapshotTable(
    table,
    tableIndex
) {
    const rowCount = Number(
        table.rowCount()
    );

    const columnCount = Number(
        table.columnCount()
    );

    const bulkRows =
        snapshotRowsBulk(
            table,
            rowCount,
            columnCount
        );

    const rows =
        bulkRows === null
            ? table.rows().map(
                (row, rowOffset) =>
                    snapshotRow(
                        row,
                        rowOffset + 1
                    )
            )
            : bulkRows;

    return {
        index: tableIndex,
        name: String(
            table.name()
        ),
        rowCount: rowCount,
        columnCount: columnCount,
        headerRowCount: Number(
            table.headerRowCount()
        ),
        headerColumnCount: Number(
            table.headerColumnCount()
        ),
        footerRowCount: Number(
            table.footerRowCount()
        ),
        rows: rows
    };
}

function snapshotSheet(
    sheet,
    sheetIndex
) {
    const tables = sheet.tables();

    return {
        index: sheetIndex,
        name: String(
            sheet.name()
        ),
        tables: tables.map(
            (table, tableOffset) =>
                snapshotTable(
                    table,
                    tableOffset + 1
                )
        )
    };
}

function snapshotDocument(
    document
) {
    const sheets = document.sheets();

    return {
        name: String(
            document.name()
        ),
        sheets: sheets.map(
            (sheet, sheetOffset) =>
                snapshotSheet(
                    sheet,
                    sheetOffset + 1
                )
        )
    };
}

function samePath(
    lhs,
    rhs
) {
    if (lhs === null) {
        return false;
    }

    const left = String(lhs);

    return (
        left === rhs
        || left.replace(/^file:\/\//, "") === rhs
    );
}

function openDocument(
    Numbers,
    documentPath
) {
    const documents = Numbers.documents();

    for (
        let index = 0;
        index < documents.length;
        index += 1
    ) {
        const document = documents[index];

        const file = safeProperty(
            () => document.file()
        );

        if (
            samePath(
                file,
                documentPath
            )
        ) {
            return {
                document: document,
                closeWhenDone: false
            };
        }
    }

    return {
        document:
            Numbers.open(
                Path(
                    documentPath
                )
            ),
        closeWhenDone: true
    };
}

function run(argv) {
    if (argv.length !== 1) {
        throw new Error(
            "Expected exactly one Numbers document path"
        );
    }

    const Numbers = Application(
        "Numbers"
    );

    Numbers.includeStandardAdditions = true;

    const opened = openDocument(
        Numbers,
        argv[0]
    );

    try {
        return JSON.stringify(
            snapshotDocument(
                opened.document
            )
        );
    } finally {
        if (opened.closeWhenDone) {
            opened.document.close(
                {
                    saving: "no"
                }
            );
        }
    }
}
"""#
}
