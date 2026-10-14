@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormClaimTests {
    @Test func startsInProposed() throws {
        let item = Consent.newScheduledConsentFormClaim("code-443", title: "title-782")
        #expect(item.status == Consent.ScheduledConsentFormClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newScheduledConsentFormClaim("code-443", title: "title-782")
        try item.moveTo(Consent.ScheduledConsentFormClaimStatus.approved)
        #expect(item.status == Consent.ScheduledConsentFormClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newScheduledConsentFormClaim("code-443", title: "title-782")
        item.status = Consent.ScheduledConsentFormClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledConsentFormClaimStatus.proposed) }
    }
}
