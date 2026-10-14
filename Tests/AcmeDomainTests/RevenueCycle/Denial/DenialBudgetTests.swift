@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBudgetTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newDenialBudget("code-774", title: "title-698")
        #expect(item.status == RevenueCycle.DenialBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newDenialBudget("code-774", title: "title-698")
        try item.moveTo(RevenueCycle.DenialBudgetStatus.inReview)
        #expect(item.status == RevenueCycle.DenialBudgetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newDenialBudget("code-774", title: "title-698")
        item.status = RevenueCycle.DenialBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialBudgetStatus.`open`) }
    }
}
