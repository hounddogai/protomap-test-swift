@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPlanTests {
    @Test func startsInOpen() throws {
        let item = Consent.newConsentFormPlan("code-215", name: "name-45")
        #expect(item.status == Consent.ConsentFormPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newConsentFormPlan("code-215", name: "name-45")
        try item.moveTo(Consent.ConsentFormPlanStatus.resolved)
        #expect(item.status == Consent.ConsentFormPlanStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newConsentFormPlan("code-215", name: "name-45")
        item.status = Consent.ConsentFormPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormPlanStatus.`open`) }
    }
}
