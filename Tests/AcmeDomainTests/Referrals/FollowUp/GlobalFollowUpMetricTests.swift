@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpMetricTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newGlobalFollowUpMetric("code-635", name: "name-475")
        #expect(item.status == Referrals.GlobalFollowUpMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newGlobalFollowUpMetric("code-635", name: "name-475")
        try item.moveTo(Referrals.GlobalFollowUpMetricStatus.revoked)
        #expect(item.status == Referrals.GlobalFollowUpMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newGlobalFollowUpMetric("code-635", name: "name-475")
        item.status = Referrals.GlobalFollowUpMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalFollowUpMetricStatus.requested) }
    }
}
