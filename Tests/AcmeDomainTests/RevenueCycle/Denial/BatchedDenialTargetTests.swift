@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialTargetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newBatchedDenialTarget("code-42", name: "name-739")
        #expect(item.status == RevenueCycle.BatchedDenialTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newBatchedDenialTarget("code-42", name: "name-739")
        try item.moveTo(RevenueCycle.BatchedDenialTargetStatus.ready)
        #expect(item.status == RevenueCycle.BatchedDenialTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newBatchedDenialTarget("code-42", name: "name-739")
        item.status = RevenueCycle.BatchedDenialTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedDenialTargetStatus.idle) }
    }
}
