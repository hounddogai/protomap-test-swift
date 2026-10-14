@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyBudgetTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        #expect(item.status == Consent.LegacyProxyBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        try item.moveTo(Consent.LegacyProxyBudgetStatus.pending)
        #expect(item.status == Consent.LegacyProxyBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        item.status = Consent.LegacyProxyBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyProxyBudgetStatus.draft) }
    }
}
