@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkMetricTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkMetric("code-435", label: "label-891")
        #expect(item.status == Referrals.NetworkMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newNetworkMetric("code-435", label: "label-891")
        try item.moveTo(Referrals.NetworkMetricStatus.inProgress)
        #expect(item.status == Referrals.NetworkMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkMetric("code-435", label: "label-891")
        item.status = Referrals.NetworkMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkMetricStatus.planned) }
    }
}
