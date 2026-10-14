@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBudgetTests {
    @Test func startsInNew() throws {
        let item = Consent.newStrictProxyBudget("code-904", title: "title-917")
        #expect(item.status == Consent.StrictProxyBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newStrictProxyBudget("code-904", title: "title-917")
        try item.moveTo(Consent.StrictProxyBudgetStatus.done)
        #expect(item.status == Consent.StrictProxyBudgetStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newStrictProxyBudget("code-904", title: "title-917")
        item.status = Consent.StrictProxyBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictProxyBudgetStatus.new) }
    }
}
