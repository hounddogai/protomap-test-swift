@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newTieredReferralMilestone("code-613", title: "title-714")
        #expect(item.status == Referrals.TieredReferralMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newTieredReferralMilestone("code-613", title: "title-714")
        try item.moveTo(Referrals.TieredReferralMilestoneStatus.granted)
        #expect(item.status == Referrals.TieredReferralMilestoneStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newTieredReferralMilestone("code-613", title: "title-714")
        item.status = Referrals.TieredReferralMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredReferralMilestoneStatus.requested) }
    }
}
