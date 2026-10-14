@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpMetricTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newTieredFollowUpMetric("code-886", label: "label-993")
        #expect(item.status == Referrals.TieredFollowUpMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newTieredFollowUpMetric("code-886", label: "label-993")
        try item.moveTo(Referrals.TieredFollowUpMetricStatus.draining)
        #expect(item.status == Referrals.TieredFollowUpMetricStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newTieredFollowUpMetric("code-886", label: "label-993")
        item.status = Referrals.TieredFollowUpMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpMetricStatus.idle) }
    }
}
