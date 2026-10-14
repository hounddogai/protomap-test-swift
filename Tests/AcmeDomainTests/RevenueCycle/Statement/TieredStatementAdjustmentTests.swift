@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredStatementAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newTieredStatementAdjustment("code-763", label: "label-449")
        #expect(item.status == RevenueCycle.TieredStatementAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newTieredStatementAdjustment("code-763", label: "label-449")
        try item.moveTo(RevenueCycle.TieredStatementAdjustmentStatus.withdrawn)
        #expect(item.status == RevenueCycle.TieredStatementAdjustmentStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newTieredStatementAdjustment("code-763", label: "label-449")
        item.status = RevenueCycle.TieredStatementAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredStatementAdjustmentStatus.proposed) }
    }
}
