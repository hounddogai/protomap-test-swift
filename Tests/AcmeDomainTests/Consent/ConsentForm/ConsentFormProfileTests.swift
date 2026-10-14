@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormProfileTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormProfile("code-928", name: "name-816")
        #expect(item.status == Consent.ConsentFormProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newConsentFormProfile("code-928", name: "name-816")
        try item.moveTo(Consent.ConsentFormProfileStatus.retired)
        #expect(item.status == Consent.ConsentFormProfileStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormProfile("code-928", name: "name-816")
        item.status = Consent.ConsentFormProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormProfileStatus.created) }
    }
}
