@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimBudgetTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newLegacyClaimBudget("code-673", title: "title-936")
        #expect(item.status == RevenueCycle.LegacyClaimBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newLegacyClaimBudget("code-673", title: "title-936")
        try item.moveTo(RevenueCycle.LegacyClaimBudgetStatus.rejected)
        #expect(item.status == RevenueCycle.LegacyClaimBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newLegacyClaimBudget("code-673", title: "title-936")
        item.status = RevenueCycle.LegacyClaimBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyClaimBudgetStatus.proposed) }
    }
}
