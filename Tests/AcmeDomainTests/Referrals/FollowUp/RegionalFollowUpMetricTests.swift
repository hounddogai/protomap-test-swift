@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpMetricTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newRegionalFollowUpMetric("code-343", label: "label-262")
        #expect(item.status == Referrals.RegionalFollowUpMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newRegionalFollowUpMetric("code-343", label: "label-262")
        try item.moveTo(Referrals.RegionalFollowUpMetricStatus.scheduled)
        #expect(item.status == Referrals.RegionalFollowUpMetricStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newRegionalFollowUpMetric("code-343", label: "label-262")
        item.status = Referrals.RegionalFollowUpMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalFollowUpMetricStatus.planned) }
    }
}
