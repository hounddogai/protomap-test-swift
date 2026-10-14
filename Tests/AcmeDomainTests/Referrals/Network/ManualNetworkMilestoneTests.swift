@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        #expect(item.status == Referrals.ManualNetworkMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        try item.moveTo(Referrals.ManualNetworkMilestoneStatus.rejected)
        #expect(item.status == Referrals.ManualNetworkMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        item.status = Referrals.ManualNetworkMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkMilestoneStatus.proposed) }
    }
}
