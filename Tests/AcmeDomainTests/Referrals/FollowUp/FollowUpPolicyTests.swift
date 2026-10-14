@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPolicyTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFollowUpPolicy("code-506", label: "label-920")
        #expect(item.status == Referrals.FollowUpPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newFollowUpPolicy("code-506", label: "label-920")
        try item.moveTo(Referrals.FollowUpPolicyStatus.rejected)
        #expect(item.status == Referrals.FollowUpPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFollowUpPolicy("code-506", label: "label-920")
        item.status = Referrals.FollowUpPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpPolicyStatus.proposed) }
    }
}
