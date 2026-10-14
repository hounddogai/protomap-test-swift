@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualChargeAssignmentTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newManualChargeAssignment("code-632", name: "name-309")
        #expect(item.status == RevenueCycle.ManualChargeAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newManualChargeAssignment("code-632", name: "name-309")
        try item.moveTo(RevenueCycle.ManualChargeAssignmentStatus.warming)
        #expect(item.status == RevenueCycle.ManualChargeAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newManualChargeAssignment("code-632", name: "name-309")
        item.status = RevenueCycle.ManualChargeAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualChargeAssignmentStatus.idle) }
    }
}
