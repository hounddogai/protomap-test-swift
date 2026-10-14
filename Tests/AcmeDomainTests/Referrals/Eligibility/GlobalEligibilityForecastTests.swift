@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityForecastTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newGlobalEligibilityForecast("code-127", label: "label-643")
        #expect(item.status == Referrals.GlobalEligibilityForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newGlobalEligibilityForecast("code-127", label: "label-643")
        try item.moveTo(Referrals.GlobalEligibilityForecastStatus.granted)
        #expect(item.status == Referrals.GlobalEligibilityForecastStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newGlobalEligibilityForecast("code-127", label: "label-643")
        item.status = Referrals.GlobalEligibilityForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalEligibilityForecastStatus.requested) }
    }
}
