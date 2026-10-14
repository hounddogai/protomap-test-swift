@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newBatchedClaimMilestone("code-199", title: "title-207")
        #expect(item.status == RevenueCycle.BatchedClaimMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newBatchedClaimMilestone("code-199", title: "title-207")
        try item.moveTo(RevenueCycle.BatchedClaimMilestoneStatus.completed)
        #expect(item.status == RevenueCycle.BatchedClaimMilestoneStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newBatchedClaimMilestone("code-199", title: "title-207")
        item.status = RevenueCycle.BatchedClaimMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedClaimMilestoneStatus.planned) }
    }
}
