@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormEntryTests {
    @Test func startsInRequested() throws {
        let item = Consent.newPrimaryConsentFormEntry("code-123", name: "name-94")
        #expect(item.status == Consent.PrimaryConsentFormEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newPrimaryConsentFormEntry("code-123", name: "name-94")
        try item.moveTo(Consent.PrimaryConsentFormEntryStatus.revoked)
        #expect(item.status == Consent.PrimaryConsentFormEntryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newPrimaryConsentFormEntry("code-123", name: "name-94")
        item.status = Consent.PrimaryConsentFormEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryConsentFormEntryStatus.requested) }
    }
}
