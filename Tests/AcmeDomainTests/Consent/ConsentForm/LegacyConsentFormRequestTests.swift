@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyConsentFormRequestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLegacyConsentFormRequest("code-929", label: "label-321")
        #expect(item.status == Consent.LegacyConsentFormRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLegacyConsentFormRequest("code-929", label: "label-321")
        try item.moveTo(Consent.LegacyConsentFormRequestStatus.approved)
        #expect(item.status == Consent.LegacyConsentFormRequestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLegacyConsentFormRequest("code-929", label: "label-321")
        item.status = Consent.LegacyConsentFormRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyConsentFormRequestStatus.proposed) }
    }
}
