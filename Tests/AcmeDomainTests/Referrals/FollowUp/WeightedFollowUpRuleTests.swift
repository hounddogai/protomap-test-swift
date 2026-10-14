@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpRuleTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newWeightedFollowUpRule("code-88", label: "label-214")
        #expect(item.status == Referrals.WeightedFollowUpRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newWeightedFollowUpRule("code-88", label: "label-214")
        try item.moveTo(Referrals.WeightedFollowUpRuleStatus.revoked)
        #expect(item.status == Referrals.WeightedFollowUpRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newWeightedFollowUpRule("code-88", label: "label-214")
        item.status = Referrals.WeightedFollowUpRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedFollowUpRuleStatus.requested) }
    }
}
