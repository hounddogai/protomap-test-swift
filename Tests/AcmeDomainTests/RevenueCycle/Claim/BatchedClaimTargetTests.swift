@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimTargetTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newBatchedClaimTarget("code-23", label: "label-38")
        #expect(item.status == RevenueCycle.BatchedClaimTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newBatchedClaimTarget("code-23", label: "label-38")
        try item.moveTo(RevenueCycle.BatchedClaimTargetStatus.failed)
        #expect(item.status == RevenueCycle.BatchedClaimTargetStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newBatchedClaimTarget("code-23", label: "label-38")
        item.status = RevenueCycle.BatchedClaimTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedClaimTargetStatus.new) }
    }
}
