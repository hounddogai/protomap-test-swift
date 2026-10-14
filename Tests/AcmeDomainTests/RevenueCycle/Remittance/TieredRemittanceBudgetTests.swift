@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceBudgetTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newTieredRemittanceBudget("code-90", name: "name-385")
        #expect(item.status == RevenueCycle.TieredRemittanceBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newTieredRemittanceBudget("code-90", name: "name-385")
        try item.moveTo(RevenueCycle.TieredRemittanceBudgetStatus.rejected)
        #expect(item.status == RevenueCycle.TieredRemittanceBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newTieredRemittanceBudget("code-90", name: "name-385")
        item.status = RevenueCycle.TieredRemittanceBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceBudgetStatus.proposed) }
    }
}
