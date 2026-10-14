@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialPolicyTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        #expect(item.status == RevenueCycle.BatchedDenialPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        try item.moveTo(RevenueCycle.BatchedDenialPolicyStatus.draining)
        #expect(item.status == RevenueCycle.BatchedDenialPolicyStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        item.status = RevenueCycle.BatchedDenialPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedDenialPolicyStatus.idle) }
    }
}
