@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEstimateTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRollingRemittanceEstimate("code-566", label: "label-200")
        #expect(item.status == RevenueCycle.RollingRemittanceEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRollingRemittanceEstimate("code-566", label: "label-200")
        try item.moveTo(RevenueCycle.RollingRemittanceEstimateStatus.warming)
        #expect(item.status == RevenueCycle.RollingRemittanceEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRollingRemittanceEstimate("code-566", label: "label-200")
        item.status = RevenueCycle.RollingRemittanceEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingRemittanceEstimateStatus.idle) }
    }
}
