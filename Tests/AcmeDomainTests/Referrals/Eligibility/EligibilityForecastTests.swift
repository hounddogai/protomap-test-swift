@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityForecastTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityForecast("code-703", label: "label-903")
        #expect(item.status == Referrals.EligibilityForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newEligibilityForecast("code-703", label: "label-903")
        try item.moveTo(Referrals.EligibilityForecastStatus.pending)
        #expect(item.status == Referrals.EligibilityForecastStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityForecast("code-703", label: "label-903")
        item.status = Referrals.EligibilityForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityForecastStatus.draft) }
    }
}
