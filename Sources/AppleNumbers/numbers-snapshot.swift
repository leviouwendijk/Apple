public struct NumbersCellSnapshot:
    Codable,
    Hashable,
    Sendable
{
    public let row: Int
    public let column: Int
    public let address: String
    public let value: NumbersCellValue
    public let format: NumbersCellFormat
    public let formula: String?
    public let formatted: String?

    public init(
        row: Int,
        column: Int,
        address: String,
        value: NumbersCellValue,
        format: NumbersCellFormat,
        formula: String? = nil,
        formatted: String? = nil
    ) {
        self.row = row
        self.column = column
        self.address = address
        self.value = value
        self.format = format
        self.formula = formula
        self.formatted = formatted
    }
}

public struct NumbersRowSnapshot:
    Codable,
    Hashable,
    Sendable
{
    public let index: Int
    public let cells: [NumbersCellSnapshot]

    public init(
        index: Int,
        cells: [NumbersCellSnapshot]
    ) {
        self.index = index
        self.cells = cells
    }
}

public struct NumbersTableSnapshot:
    Codable,
    Hashable,
    Sendable
{
    public let index: Int
    public let name: String

    public let rowCount: Int
    public let columnCount: Int

    public let headerRowCount: Int
    public let headerColumnCount: Int
    public let footerRowCount: Int

    public let rows: [NumbersRowSnapshot]

    public init(
        index: Int,
        name: String,
        rowCount: Int,
        columnCount: Int,
        headerRowCount: Int,
        headerColumnCount: Int,
        footerRowCount: Int,
        rows: [NumbersRowSnapshot]
    ) {
        self.index = index
        self.name = name
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.headerRowCount = headerRowCount
        self.headerColumnCount = headerColumnCount
        self.footerRowCount = footerRowCount
        self.rows = rows
    }
}

public struct NumbersSheetSnapshot:
    Codable,
    Hashable,
    Sendable
{
    public let index: Int
    public let name: String
    public let tables: [NumbersTableSnapshot]

    public init(
        index: Int,
        name: String,
        tables: [NumbersTableSnapshot]
    ) {
        self.index = index
        self.name = name
        self.tables = tables
    }
}

public struct NumbersSnapshot:
    Codable,
    Hashable,
    Sendable
{
    public let name: String
    public let sheets: [NumbersSheetSnapshot]

    public init(
        name: String,
        sheets: [NumbersSheetSnapshot]
    ) {
        self.name = name
        self.sheets = sheets
    }
}
