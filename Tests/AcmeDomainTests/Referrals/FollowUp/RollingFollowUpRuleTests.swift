@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingFollowUpRuleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        #expect(item.status == Referrals.RollingFollowUpRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        try item.moveTo(Referrals.RollingFollowUpRuleStatus.rejected)
        #expect(item.status == Referrals.RollingFollowUpRuleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        item.status = Referrals.RollingFollowUpRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingFollowUpRuleStatus.proposed) }
    }
}
