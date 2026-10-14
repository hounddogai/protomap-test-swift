@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualChargeOverrideTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newManualChargeOverride("code-468", name: "name-759")
        #expect(item.status == RevenueCycle.ManualChargeOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newManualChargeOverride("code-468", name: "name-759")
        try item.moveTo(RevenueCycle.ManualChargeOverrideStatus.stopped)
        #expect(item.status == RevenueCycle.ManualChargeOverrideStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newManualChargeOverride("code-468", name: "name-759")
        item.status = RevenueCycle.ManualChargeOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualChargeOverrideStatus.idle) }
    }
}
