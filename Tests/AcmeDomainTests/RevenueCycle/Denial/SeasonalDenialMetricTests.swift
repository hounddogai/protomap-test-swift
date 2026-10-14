@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalDenialMetricTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newSeasonalDenialMetric("code-150", title: "title-70")
        #expect(item.status == RevenueCycle.SeasonalDenialMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newSeasonalDenialMetric("code-150", title: "title-70")
        try item.moveTo(RevenueCycle.SeasonalDenialMetricStatus.revoked)
        #expect(item.status == RevenueCycle.SeasonalDenialMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newSeasonalDenialMetric("code-150", title: "title-70")
        item.status = RevenueCycle.SeasonalDenialMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.SeasonalDenialMetricStatus.requested) }
    }
}
