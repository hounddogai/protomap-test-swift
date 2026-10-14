@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAllocationTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceAllocation("code-775", label: "label-238")
        #expect(item.status == RevenueCycle.RemittanceAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newRemittanceAllocation("code-775", label: "label-238")
        try item.moveTo(RevenueCycle.RemittanceAllocationStatus.draining)
        #expect(item.status == RevenueCycle.RemittanceAllocationStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceAllocation("code-775", label: "label-238")
        item.status = RevenueCycle.RemittanceAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceAllocationStatus.idle) }
    }
}
