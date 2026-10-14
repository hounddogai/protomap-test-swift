@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedFollowUpTemplateTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newBatchedFollowUpTemplate("code-199", title: "title-719")
        #expect(item.status == Referrals.BatchedFollowUpTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newBatchedFollowUpTemplate("code-199", title: "title-719")
        try item.moveTo(Referrals.BatchedFollowUpTemplateStatus.draining)
        #expect(item.status == Referrals.BatchedFollowUpTemplateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newBatchedFollowUpTemplate("code-199", title: "title-719")
        item.status = Referrals.BatchedFollowUpTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedFollowUpTemplateStatus.idle) }
    }
}
