@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveEligibilityForecastTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newAdaptiveEligibilityForecast("code-925", name: "name-496")
        #expect(item.status == Referrals.AdaptiveEligibilityForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newAdaptiveEligibilityForecast("code-925", name: "name-496")
        try item.moveTo(Referrals.AdaptiveEligibilityForecastStatus.inReview)
        #expect(item.status == Referrals.AdaptiveEligibilityForecastStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newAdaptiveEligibilityForecast("code-925", name: "name-496")
        item.status = Referrals.AdaptiveEligibilityForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveEligibilityForecastStatus.`open`) }
    }
}
