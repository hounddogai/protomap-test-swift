@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingRemittanceAllocationTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newPendingRemittanceAllocation("code-763", label: "label-846")
        #expect(item.status == RevenueCycle.PendingRemittanceAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newPendingRemittanceAllocation("code-763", label: "label-846")
        try item.moveTo(RevenueCycle.PendingRemittanceAllocationStatus.withdrawn)
        #expect(item.status == RevenueCycle.PendingRemittanceAllocationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newPendingRemittanceAllocation("code-763", label: "label-846")
        item.status = RevenueCycle.PendingRemittanceAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingRemittanceAllocationStatus.proposed) }
    }
}
