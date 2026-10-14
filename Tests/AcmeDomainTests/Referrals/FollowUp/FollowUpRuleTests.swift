@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRuleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newFollowUpRule("code-881", title: "title-701")
        #expect(item.status == Referrals.FollowUpRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newFollowUpRule("code-881", title: "title-701")
        try item.moveTo(Referrals.FollowUpRuleStatus.draining)
        #expect(item.status == Referrals.FollowUpRuleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newFollowUpRule("code-881", title: "title-701")
        item.status = Referrals.FollowUpRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpRuleStatus.idle) }
    }
}
