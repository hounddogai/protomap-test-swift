@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBaselineTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFollowUpBaseline("code-68", title: "title-170")
        #expect(item.status == Referrals.FollowUpBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newFollowUpBaseline("code-68", title: "title-170")
        try item.moveTo(Referrals.FollowUpBaselineStatus.approved)
        #expect(item.status == Referrals.FollowUpBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFollowUpBaseline("code-68", title: "title-170")
        item.status = Referrals.FollowUpBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpBaselineStatus.proposed) }
    }
}
