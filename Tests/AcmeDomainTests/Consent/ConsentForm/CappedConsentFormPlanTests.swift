@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormPlanTests {
    @Test func startsInDraft() throws {
        let item = Consent.newCappedConsentFormPlan("code-914", title: "title-549")
        #expect(item.status == Consent.CappedConsentFormPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newCappedConsentFormPlan("code-914", title: "title-549")
        try item.moveTo(Consent.CappedConsentFormPlanStatus.suspended)
        #expect(item.status == Consent.CappedConsentFormPlanStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newCappedConsentFormPlan("code-914", title: "title-549")
        item.status = Consent.CappedConsentFormPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedConsentFormPlanStatus.draft) }
    }
}
