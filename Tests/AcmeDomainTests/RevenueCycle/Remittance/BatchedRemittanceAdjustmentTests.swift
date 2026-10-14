@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newBatchedRemittanceAdjustment("code-889", name: "name-710")
        #expect(item.status == RevenueCycle.BatchedRemittanceAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newBatchedRemittanceAdjustment("code-889", name: "name-710")
        try item.moveTo(RevenueCycle.BatchedRemittanceAdjustmentStatus.ready)
        #expect(item.status == RevenueCycle.BatchedRemittanceAdjustmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newBatchedRemittanceAdjustment("code-889", name: "name-710")
        item.status = RevenueCycle.BatchedRemittanceAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedRemittanceAdjustmentStatus.idle) }
    }
}
