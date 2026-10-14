@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageBudgetTests {
    @Test func startsInOpen() throws {
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        #expect(item.status == Consent.FallbackLanguageBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        try item.moveTo(Consent.FallbackLanguageBudgetStatus.inReview)
        #expect(item.status == Consent.FallbackLanguageBudgetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        item.status = Consent.FallbackLanguageBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackLanguageBudgetStatus.`open`) }
    }
}
