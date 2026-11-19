public struct NumbersTableReference:
    Codable,
    Hashable,
    Sendable,
    Comparable
{
    public let sheet: Int
    public let table: Int

    public init(
        sheet: Int,
        table: Int
    ) {
        self.sheet = sheet
        self.table = table
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        if lhs.sheet != rhs.sheet {
            return lhs.sheet < rhs.sheet
        }

        return lhs.table < rhs.table
    }
}

public struct NumbersFieldReference:
    Codable,
    Hashable,
    Sendable,
    Comparable
{
    public let table: NumbersTableReference
    public let column: Int

    public init(
        table: NumbersTableReference,
        column: Int
    ) {
        self.table = table
        self.column = column
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        if lhs.table != rhs.table {
            return lhs.table < rhs.table
        }

        return lhs.column < rhs.column
    }
}

public enum NumbersFieldType:
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
    case mixed
}

public struct NumbersFieldSchema:
    Codable,
    Hashable,
    Sendable
{
    public let source: NumbersFieldReference
    public let sourceName: String?

    public let type: NumbersFieldType
    public let formats: [NumbersCellFormat]
    public let optional: Bool

    public let rowCount: Int
    public let nonEmptyCount: Int
    public let distinctCount: Int

    public init(
        source: NumbersFieldReference,
        sourceName: String?,
        type: NumbersFieldType,
        formats: [NumbersCellFormat],
        optional: Bool,
        rowCount: Int,
        nonEmptyCount: Int,
        distinctCount: Int
    ) {
        self.source = source
        self.sourceName = sourceName
        self.type = type
        self.formats = formats
        self.optional = optional
        self.rowCount = rowCount
        self.nonEmptyCount = nonEmptyCount
        self.distinctCount = distinctCount
    }
}

public struct NumbersModelSchema:
    Codable,
    Hashable,
    Sendable
{
    public let source: NumbersTableReference
    public let name: String

    public let fields: [NumbersFieldSchema]
    public let keyCandidates: [NumbersFieldReference]

    public init(
        source: NumbersTableReference,
        name: String,
        fields: [NumbersFieldSchema],
        keyCandidates: [NumbersFieldReference]
    ) {
        self.source = source
        self.name = name
        self.fields = fields
        self.keyCandidates = keyCandidates
    }
}

public enum NumbersRelationshipCardinality:
    String,
    Codable,
    Hashable,
    Sendable
{
    case oneToOne
    case manyToOne
}

public struct NumbersRelationshipEvidence:
    Codable,
    Hashable,
    Sendable
{
    public let sourceNonEmptyCount: Int
    public let sourceDistinctCount: Int
    public let matchedDistinctCount: Int
    public let coverage: Double
    public let headerMatch: Bool

    public init(
        sourceNonEmptyCount: Int,
        sourceDistinctCount: Int,
        matchedDistinctCount: Int,
        coverage: Double,
        headerMatch: Bool
    ) {
        self.sourceNonEmptyCount = sourceNonEmptyCount
        self.sourceDistinctCount = sourceDistinctCount
        self.matchedDistinctCount = matchedDistinctCount
        self.coverage = coverage
        self.headerMatch = headerMatch
    }
}

public struct NumbersRelationshipCandidate:
    Codable,
    Hashable,
    Sendable
{
    public let source: NumbersFieldReference
    public let target: NumbersFieldReference
    public let cardinality: NumbersRelationshipCardinality
    public let evidence: NumbersRelationshipEvidence

    public init(
        source: NumbersFieldReference,
        target: NumbersFieldReference,
        cardinality: NumbersRelationshipCardinality,
        evidence: NumbersRelationshipEvidence
    ) {
        self.source = source
        self.target = target
        self.cardinality = cardinality
        self.evidence = evidence
    }
}

public struct NumbersSchema:
    Codable,
    Hashable,
    Sendable
{
    public let models: [NumbersModelSchema]
    public let relationships: [NumbersRelationshipCandidate]

    public init(
        models: [NumbersModelSchema],
        relationships: [NumbersRelationshipCandidate]
    ) {
        self.models = models
        self.relationships = relationships
    }
}
