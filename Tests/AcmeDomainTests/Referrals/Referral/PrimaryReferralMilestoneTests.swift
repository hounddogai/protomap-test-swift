@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newPrimaryReferralMilestone("code-916", title: "title-17")
        #expect(item.status == Referrals.PrimaryReferralMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newPrimaryReferralMilestone("code-916", title: "title-17")
        try item.moveTo(Referrals.PrimaryReferralMilestoneStatus.approved)
        #expect(item.status == Referrals.PrimaryReferralMilestoneStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newPrimaryReferralMilestone("code-916", title: "title-17")
        item.status = Referrals.PrimaryReferralMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryReferralMilestoneStatus.proposed) }
    }
}
