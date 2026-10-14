@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTargetTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFollowUpTarget("code-900", name: "name-319")
        #expect(item.status == Referrals.FollowUpTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newFollowUpTarget("code-900", name: "name-319")
        try item.moveTo(Referrals.FollowUpTargetStatus.rejected)
        #expect(item.status == Referrals.FollowUpTargetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFollowUpTarget("code-900", name: "name-319")
        item.status = Referrals.FollowUpTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpTargetStatus.proposed) }
    }
}
