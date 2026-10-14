@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimPlanTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRollingClaimPlan("code-889", title: "title-162")
        #expect(item.status == RevenueCycle.RollingClaimPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRollingClaimPlan("code-889", title: "title-162")
        try item.moveTo(RevenueCycle.RollingClaimPlanStatus.warming)
        #expect(item.status == RevenueCycle.RollingClaimPlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRollingClaimPlan("code-889", title: "title-162")
        item.status = RevenueCycle.RollingClaimPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingClaimPlanStatus.idle) }
    }
}
