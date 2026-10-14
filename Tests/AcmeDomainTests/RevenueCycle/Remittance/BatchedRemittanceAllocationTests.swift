@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceAllocationTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newBatchedRemittanceAllocation("code-750", label: "label-742")
        #expect(item.status == RevenueCycle.BatchedRemittanceAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newBatchedRemittanceAllocation("code-750", label: "label-742")
        try item.moveTo(RevenueCycle.BatchedRemittanceAllocationStatus.running)
        #expect(item.status == RevenueCycle.BatchedRemittanceAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newBatchedRemittanceAllocation("code-750", label: "label-742")
        item.status = RevenueCycle.BatchedRemittanceAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedRemittanceAllocationStatus.new) }
    }
}
