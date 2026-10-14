@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormClaimTests {
    @Test func startsInDraft() throws {
        let item = Consent.newConsentFormClaim("code-795", label: "label-111")
        #expect(item.status == Consent.ConsentFormClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newConsentFormClaim("code-795", label: "label-111")
        try item.moveTo(Consent.ConsentFormClaimStatus.pending)
        #expect(item.status == Consent.ConsentFormClaimStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newConsentFormClaim("code-795", label: "label-111")
        item.status = Consent.ConsentFormClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormClaimStatus.draft) }
    }
}
