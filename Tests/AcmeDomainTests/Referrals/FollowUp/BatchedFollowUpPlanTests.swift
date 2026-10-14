@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedFollowUpPlanTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newBatchedFollowUpPlan("code-207", title: "title-690")
        #expect(item.status == Referrals.BatchedFollowUpPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newBatchedFollowUpPlan("code-207", title: "title-690")
        try item.moveTo(Referrals.BatchedFollowUpPlanStatus.pending)
        #expect(item.status == Referrals.BatchedFollowUpPlanStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newBatchedFollowUpPlan("code-207", title: "title-690")
        item.status = Referrals.BatchedFollowUpPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedFollowUpPlanStatus.draft) }
    }
}
