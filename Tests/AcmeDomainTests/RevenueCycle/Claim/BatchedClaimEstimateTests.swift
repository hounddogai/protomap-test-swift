@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimEstimateTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newBatchedClaimEstimate("code-305", title: "title-546")
        #expect(item.status == RevenueCycle.BatchedClaimEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newBatchedClaimEstimate("code-305", title: "title-546")
        try item.moveTo(RevenueCycle.BatchedClaimEstimateStatus.completed)
        #expect(item.status == RevenueCycle.BatchedClaimEstimateStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newBatchedClaimEstimate("code-305", title: "title-546")
        item.status = RevenueCycle.BatchedClaimEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedClaimEstimateStatus.planned) }
    }
}
