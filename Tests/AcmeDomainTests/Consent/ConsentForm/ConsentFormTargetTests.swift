@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormTargetTests {
    @Test func startsInDraft() throws {
        let item = Consent.newConsentFormTarget("code-380", name: "name-123")
        #expect(item.status == Consent.ConsentFormTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newConsentFormTarget("code-380", name: "name-123")
        try item.moveTo(Consent.ConsentFormTargetStatus.active)
        #expect(item.status == Consent.ConsentFormTargetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newConsentFormTarget("code-380", name: "name-123")
        item.status = Consent.ConsentFormTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormTargetStatus.draft) }
    }
}
