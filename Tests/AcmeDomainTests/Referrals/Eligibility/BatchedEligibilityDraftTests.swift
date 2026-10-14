@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityDraftTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        #expect(item.status == Referrals.BatchedEligibilityDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        try item.moveTo(Referrals.BatchedEligibilityDraftStatus.approved)
        #expect(item.status == Referrals.BatchedEligibilityDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        item.status = Referrals.BatchedEligibilityDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedEligibilityDraftStatus.proposed) }
    }
}
