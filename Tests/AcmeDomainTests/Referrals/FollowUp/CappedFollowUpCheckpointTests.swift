@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpCheckpointTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedFollowUpCheckpoint("code-854", title: "title-643")
        #expect(item.status == Referrals.CappedFollowUpCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newCappedFollowUpCheckpoint("code-854", title: "title-643")
        try item.moveTo(Referrals.CappedFollowUpCheckpointStatus.approved)
        #expect(item.status == Referrals.CappedFollowUpCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedFollowUpCheckpoint("code-854", title: "title-643")
        item.status = Referrals.CappedFollowUpCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedFollowUpCheckpointStatus.proposed) }
    }
}
