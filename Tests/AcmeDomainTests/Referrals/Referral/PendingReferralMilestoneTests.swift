@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        #expect(item.status == Referrals.PendingReferralMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        try item.moveTo(Referrals.PendingReferralMilestoneStatus.suspended)
        #expect(item.status == Referrals.PendingReferralMilestoneStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        item.status = Referrals.PendingReferralMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingReferralMilestoneStatus.draft) }
    }
}
