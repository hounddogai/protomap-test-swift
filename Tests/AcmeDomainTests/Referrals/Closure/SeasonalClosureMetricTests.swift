@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureMetricTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSeasonalClosureMetric("code-309", name: "name-802")
        #expect(item.status == Referrals.SeasonalClosureMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Referrals.newSeasonalClosureMetric("code-309", name: "name-802")
        try item.moveTo(Referrals.SeasonalClosureMetricStatus.withdrawn)
        #expect(item.status == Referrals.SeasonalClosureMetricStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSeasonalClosureMetric("code-309", name: "name-802")
        item.status = Referrals.SeasonalClosureMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureMetricStatus.proposed) }
    }
}
