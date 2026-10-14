@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStatementAdjustment("code-520", label: "label-769")
        #expect(item.status == RevenueCycle.StatementAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newStatementAdjustment("code-520", label: "label-769")
        try item.moveTo(RevenueCycle.StatementAdjustmentStatus.rejected)
        #expect(item.status == RevenueCycle.StatementAdjustmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStatementAdjustment("code-520", label: "label-769")
        item.status = RevenueCycle.StatementAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementAdjustmentStatus.proposed) }
    }
}
