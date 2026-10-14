@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newPrimaryLanguageBudget("code-288", label: "label-348")
        #expect(item.status == Consent.PrimaryLanguageBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newPrimaryLanguageBudget("code-288", label: "label-348")
        try item.moveTo(Consent.PrimaryLanguageBudgetStatus.scheduled)
        #expect(item.status == Consent.PrimaryLanguageBudgetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newPrimaryLanguageBudget("code-288", label: "label-348")
        item.status = Consent.PrimaryLanguageBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryLanguageBudgetStatus.planned) }
    }
}
