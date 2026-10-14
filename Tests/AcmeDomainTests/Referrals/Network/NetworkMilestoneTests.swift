@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkMilestone("code-232", name: "name-134")
        #expect(item.status == Referrals.NetworkMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newNetworkMilestone("code-232", name: "name-134")
        try item.moveTo(Referrals.NetworkMilestoneStatus.pending)
        #expect(item.status == Referrals.NetworkMilestoneStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkMilestone("code-232", name: "name-134")
        item.status = Referrals.NetworkMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkMilestoneStatus.draft) }
    }
}
