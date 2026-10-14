@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralDraftTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newBatchedReferralDraft("code-630", name: "name-726")
        #expect(item.status == Referrals.BatchedReferralDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newBatchedReferralDraft("code-630", name: "name-726")
        try item.moveTo(Referrals.BatchedReferralDraftStatus.rejected)
        #expect(item.status == Referrals.BatchedReferralDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newBatchedReferralDraft("code-630", name: "name-726")
        item.status = Referrals.BatchedReferralDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedReferralDraftStatus.proposed) }
    }
}
