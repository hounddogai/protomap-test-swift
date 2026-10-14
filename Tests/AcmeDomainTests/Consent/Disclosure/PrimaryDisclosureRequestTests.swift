@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRequestTests {
    @Test func startsInDraft() throws {
        let item = Consent.newPrimaryDisclosureRequest("code-716", name: "name-108")
        #expect(item.status == Consent.PrimaryDisclosureRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newPrimaryDisclosureRequest("code-716", name: "name-108")
        try item.moveTo(Consent.PrimaryDisclosureRequestStatus.active)
        #expect(item.status == Consent.PrimaryDisclosureRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newPrimaryDisclosureRequest("code-716", name: "name-108")
        item.status = Consent.PrimaryDisclosureRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryDisclosureRequestStatus.draft) }
    }
}
