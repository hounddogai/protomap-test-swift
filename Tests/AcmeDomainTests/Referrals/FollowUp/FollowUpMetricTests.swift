@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMetricTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFollowUpMetric("code-332", label: "label-555")
        #expect(item.status == Referrals.FollowUpMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newFollowUpMetric("code-332", label: "label-555")
        try item.moveTo(Referrals.FollowUpMetricStatus.approved)
        #expect(item.status == Referrals.FollowUpMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFollowUpMetric("code-332", label: "label-555")
        item.status = Referrals.FollowUpMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpMetricStatus.proposed) }
    }
}
