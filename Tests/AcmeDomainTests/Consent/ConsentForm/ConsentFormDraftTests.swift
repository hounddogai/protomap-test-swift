@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDraftTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormDraft("code-111", name: "name-680")
        #expect(item.status == Consent.ConsentFormDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newConsentFormDraft("code-111", name: "name-680")
        try item.moveTo(Consent.ConsentFormDraftStatus.rejected)
        #expect(item.status == Consent.ConsentFormDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormDraft("code-111", name: "name-680")
        item.status = Consent.ConsentFormDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormDraftStatus.proposed) }
    }
}
