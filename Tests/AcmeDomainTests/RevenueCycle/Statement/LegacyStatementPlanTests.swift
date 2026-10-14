@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementPlanTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newLegacyStatementPlan("code-271", label: "label-279")
        #expect(item.status == RevenueCycle.LegacyStatementPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newLegacyStatementPlan("code-271", label: "label-279")
        try item.moveTo(RevenueCycle.LegacyStatementPlanStatus.warming)
        #expect(item.status == RevenueCycle.LegacyStatementPlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newLegacyStatementPlan("code-271", label: "label-279")
        item.status = RevenueCycle.LegacyStatementPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyStatementPlanStatus.idle) }
    }
}
