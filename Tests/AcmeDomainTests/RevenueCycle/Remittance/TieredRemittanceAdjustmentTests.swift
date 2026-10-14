@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newTieredRemittanceAdjustment("code-386", name: "name-375")
        #expect(item.status == RevenueCycle.TieredRemittanceAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newTieredRemittanceAdjustment("code-386", name: "name-375")
        try item.moveTo(RevenueCycle.TieredRemittanceAdjustmentStatus.approved)
        #expect(item.status == RevenueCycle.TieredRemittanceAdjustmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newTieredRemittanceAdjustment("code-386", name: "name-375")
        item.status = RevenueCycle.TieredRemittanceAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceAdjustmentStatus.proposed) }
    }
}
