import Macros
import Schema

@JSONSchema
public enum ContactsAuthorizationStatus:
    String,
    Sendable,
    Codable,
    Hashable
{
    case not_determined
    case restricted
    case denied
    case authorized
    case unknown
}

@JSONSchema
public struct ContactsAuthorizationRequestResult:
    Sendable,
    Codable,
    Hashable
{
    public let granted: Bool
    public let status: ContactsAuthorizationStatus

    public init(
        granted: Bool,
        status: ContactsAuthorizationStatus
    ) {
        self.granted = granted
        self.status = status
    }
}

/// An email address or phone number with its label ("home", "work", or a
/// custom one). Contacts' built-in labels are written as plain words.
@JSONSchema
public struct ContactLabeledValue:
    Sendable,
    Codable,
    Hashable
{
    public let label: String?
    public let value: String

    public init(
        label: String? = nil,
        value: String
    ) {
        self.label = label
        self.value = value
    }
}

@JSONSchema
public enum ContactAccountKind:
    String,
    Sendable,
    Codable,
    Hashable
{
    case local
    case exchange
    case carddav
    case unknown
}

/// A Contacts account (a container): "On My Mac", iCloud, or a Google
/// account over CardDAV.
@JSONSchema
public struct ContactAccount:
    Sendable,
    Codable,
    Hashable
{
    public let identifier: String
    public let name: String
    public let kind: ContactAccountKind
    public let isDefault: Bool

    public init(
        identifier: String,
        name: String,
        kind: ContactAccountKind,
        isDefault: Bool
    ) {
        self.identifier = identifier
        self.name = name
        self.kind = kind
        self.isDefault = isDefault
    }
}

@JSONSchema
public struct ContactItem:
    Sendable,
    Codable,
    Hashable
{
    public let identifier: String
    public let givenName: String
    public let familyName: String
    public let organization: String?
    public let emails: [ContactLabeledValue]
    public let phones: [ContactLabeledValue]

    public init(
        identifier: String,
        givenName: String,
        familyName: String,
        organization: String?,
        emails: [ContactLabeledValue],
        phones: [ContactLabeledValue]
    ) {
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.organization = organization
        self.emails = emails
        self.phones = phones
    }
}

/// A new contact. Without an account it goes to the default account; a
/// group must already exist in that account.
@JSONSchema
public struct ContactCreation:
    Sendable,
    Codable,
    Hashable
{
    public let givenName: String
    public let familyName: String
    public let organization: String?
    public let emails: [ContactLabeledValue]
    public let phones: [ContactLabeledValue]
    public let accountIdentifier: String?
    public let groupName: String?

    public init(
        givenName: String,
        familyName: String,
        organization: String? = nil,
        emails: [ContactLabeledValue] = [],
        phones: [ContactLabeledValue] = [],
        accountIdentifier: String? = nil,
        groupName: String? = nil
    ) {
        self.givenName = givenName
        self.familyName = familyName
        self.organization = organization
        self.emails = emails
        self.phones = phones
        self.accountIdentifier = accountIdentifier
        self.groupName = groupName
    }
}
