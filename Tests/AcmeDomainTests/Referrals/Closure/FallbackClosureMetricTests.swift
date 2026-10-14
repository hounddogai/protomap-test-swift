@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureMetricTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFallbackClosureMetric("code-756", label: "label-934")
        #expect(item.status == Referrals.FallbackClosureMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newFallbackClosureMetric("code-756", label: "label-934")
        try item.moveTo(Referrals.FallbackClosureMetricStatus.inProgress)
        #expect(item.status == Referrals.FallbackClosureMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFallbackClosureMetric("code-756", label: "label-934")
        item.status = Referrals.FallbackClosureMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackClosureMetricStatus.planned) }
    }
}
