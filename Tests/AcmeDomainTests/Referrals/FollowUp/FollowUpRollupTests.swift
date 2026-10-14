@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRollupTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFollowUpRollup("code-953", title: "title-781")
        #expect(item.status == Referrals.FollowUpRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newFollowUpRollup("code-953", title: "title-781")
        try item.moveTo(Referrals.FollowUpRollupStatus.approved)
        #expect(item.status == Referrals.FollowUpRollupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFollowUpRollup("code-953", title: "title-781")
        item.status = Referrals.FollowUpRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpRollupStatus.proposed) }
    }
}
