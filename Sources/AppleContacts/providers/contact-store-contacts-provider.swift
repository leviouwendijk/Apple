@preconcurrency import Contacts
import Foundation

/// The Contacts app's accounts on this Mac, including Google accounts it
/// syncs over CardDAV. Access belongs to the macOS user running the process.
public actor ContactStoreContactsProvider:
    AppleContactsProvider
{
    private let store: CNContactStore

    public init(
        store: CNContactStore = .init()
    ) {
        self.store = store
    }

    public func authorizationStatus()
        -> ContactsAuthorizationStatus
    {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            return .not_determined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .unknown
        }
    }

    public func requestAccess() async throws
        -> ContactsAuthorizationRequestResult
    {
        let granted = try await store.requestAccess(
            for: .contacts
        )

        return .init(
            granted: granted,
            status: authorizationStatus()
        )
    }

    public func accounts() throws -> [ContactAccount] {
        try requireAccess()
        let defaultIdentifier = store.defaultContainerIdentifier()

        return try store.containers(matching: nil).map { container in
            ContactAccount(
                identifier: container.identifier,
                name: container.name,
                kind: Self.kind(container.type),
                isDefault: container.identifier == defaultIdentifier
            )
        }
    }

    public func contacts(
        matchingName name: String,
        limit: Int
    ) throws -> [ContactItem] {
        try requireAccess()
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw ContactStoreContactsProviderError.emptyQuery
        }
        let limit = min(max(limit, 1), 200)

        return Array(
            try store.unifiedContacts(
                matching: CNContact.predicateForContacts(matchingName: name),
                keysToFetch: Self.keys
            )
            .prefix(limit)
            .map(Self.item)
        )
    }

    public func contacts(
        withEmail email: String
    ) throws -> [ContactItem] {
        try requireAccess()
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            throw ContactStoreContactsProviderError.emptyQuery
        }

        return try store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingEmailAddress: email),
            keysToFetch: Self.keys
        )
        .map(Self.item)
    }

    public func createContact(
        _ creation: ContactCreation
    ) throws -> ContactItem {
        try requireAccess()

        let account = creation.accountIdentifier ?? store.defaultContainerIdentifier()
        guard try !store.containers(
            matching: CNContainer.predicateForContainers(withIdentifiers: [account])
        ).isEmpty else {
            throw ContactStoreContactsProviderError.accountNotFound(account)
        }

        var group: CNGroup?
        if let groupName = creation.groupName {
            group = try store.groups(
                matching: CNGroup.predicateForGroupsInContainer(withIdentifier: account)
            )
            .first { candidate in
                candidate.name.localizedCaseInsensitiveCompare(groupName) == .orderedSame
            }
            guard group != nil else {
                throw ContactStoreContactsProviderError.groupNotFound(groupName)
            }
        }

        let contact = CNMutableContact()
        contact.givenName = creation.givenName
        contact.familyName = creation.familyName
        contact.organizationName = creation.organization ?? ""
        contact.emailAddresses = creation.emails.map { email in
            CNLabeledValue(
                label: Self.storedLabel(email.label),
                value: email.value as NSString
            )
        }
        contact.phoneNumbers = creation.phones.map { phone in
            CNLabeledValue(
                label: Self.storedLabel(phone.label),
                value: CNPhoneNumber(stringValue: phone.value)
            )
        }

        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: account)
        if let group {
            request.addMember(contact, to: group)
        }
        try store.execute(request)

        return Self.item(contact)
    }
}

private extension ContactStoreContactsProvider {
    static let keys: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
    ]

    func requireAccess() throws {
        let status = authorizationStatus()
        guard status == .authorized else {
            throw ContactStoreContactsProviderError.notAuthorized(status)
        }
    }

    static func item(
        _ contact: CNContact
    ) -> ContactItem {
        ContactItem(
            identifier: contact.identifier,
            givenName: contact.givenName,
            familyName: contact.familyName,
            organization: contact.organizationName.isEmpty ? nil : contact.organizationName,
            emails: contact.emailAddresses.map { email in
                .init(label: readableLabel(email.label), value: email.value as String)
            },
            phones: contact.phoneNumbers.map { phone in
                .init(label: readableLabel(phone.label), value: phone.value.stringValue)
            }
        )
    }

    /// "_$!<Home>!$_" reads as "home"; custom labels stay as they are.
    static func readableLabel(
        _ label: String?
    ) -> String? {
        guard let label, !label.isEmpty else {
            return nil
        }
        return CNLabeledValue<NSString>.localizedString(forLabel: label).lowercased()
    }

    /// Plain "home", "work", "mobile", "main" and "other" become Contacts'
    /// built-in labels, so they show localized; anything else is custom.
    static func storedLabel(
        _ label: String?
    ) -> String? {
        guard let label else {
            return nil
        }
        switch label.lowercased() {
        case "home":
            return CNLabelHome
        case "work":
            return CNLabelWork
        case "other":
            return CNLabelOther
        case "mobile":
            return CNLabelPhoneNumberMobile
        case "main":
            return CNLabelPhoneNumberMain
        default:
            return label
        }
    }

    static func kind(
        _ type: CNContainerType
    ) -> ContactAccountKind {
        switch type {
        case .local:
            return .local
        case .exchange:
            return .exchange
        case .cardDAV:
            return .carddav
        case .unassigned:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

public enum ContactStoreContactsProviderError:
    Error,
    Sendable,
    LocalizedError
{
    case notAuthorized(ContactsAuthorizationStatus)
    case emptyQuery
    case accountNotFound(String)
    case groupNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized(let status):
            return "Contacts access is required; current status is \(status.rawValue). Grant it in System Settings > Privacy & Security > Contacts."

        case .emptyQuery:
            return "A contacts search needs a non-empty name or email address."

        case .accountNotFound(let identifier):
            return "No Contacts account with identifier '\(identifier)' was found."

        case .groupNotFound(let name):
            return "No Contacts group named '\(name)' exists in the chosen account."
        }
    }
}
