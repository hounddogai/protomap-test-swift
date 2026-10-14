@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTierTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newFollowUpTier("code-428", label: "label-176")
        #expect(item.status == Referrals.FollowUpTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newFollowUpTier("code-428", label: "label-176")
        try item.moveTo(Referrals.FollowUpTierStatus.reopened)
        #expect(item.status == Referrals.FollowUpTierStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newFollowUpTier("code-428", label: "label-176")
        item.status = Referrals.FollowUpTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpTierStatus.`open`) }
    }
}
