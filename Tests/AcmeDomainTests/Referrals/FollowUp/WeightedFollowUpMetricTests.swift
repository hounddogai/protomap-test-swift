@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpMetricTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newWeightedFollowUpMetric("code-679", title: "title-121")
        #expect(item.status == Referrals.WeightedFollowUpMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newWeightedFollowUpMetric("code-679", title: "title-121")
        try item.moveTo(Referrals.WeightedFollowUpMetricStatus.expired)
        #expect(item.status == Referrals.WeightedFollowUpMetricStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newWeightedFollowUpMetric("code-679", title: "title-121")
        item.status = Referrals.WeightedFollowUpMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedFollowUpMetricStatus.requested) }
    }
}
