public protocol AppleContactsProvider: Sendable {
    func authorizationStatus() async
        -> ContactsAuthorizationStatus

    func requestAccess() async throws
        -> ContactsAuthorizationRequestResult

    func accounts() async throws -> [ContactAccount]

    func contacts(
        matchingName name: String,
        limit: Int
    ) async throws -> [ContactItem]

    func contacts(
        withEmail email: String
    ) async throws -> [ContactItem]

    func createContact(
        _ creation: ContactCreation
    ) async throws -> ContactItem
}
