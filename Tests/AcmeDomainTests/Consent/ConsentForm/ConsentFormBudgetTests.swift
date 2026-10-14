@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBudgetTests {
    @Test func startsInIdle() throws {
        let item = Consent.newConsentFormBudget("code-735", name: "name-251")
        #expect(item.status == Consent.ConsentFormBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newConsentFormBudget("code-735", name: "name-251")
        try item.moveTo(Consent.ConsentFormBudgetStatus.stopped)
        #expect(item.status == Consent.ConsentFormBudgetStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newConsentFormBudget("code-735", name: "name-251")
        item.status = Consent.ConsentFormBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormBudgetStatus.idle) }
    }
}
