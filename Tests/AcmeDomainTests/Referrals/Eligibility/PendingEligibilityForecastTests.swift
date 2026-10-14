@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityForecastTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingEligibilityForecast("code-668", label: "label-894")
        #expect(item.status == Referrals.PendingEligibilityForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newPendingEligibilityForecast("code-668", label: "label-894")
        try item.moveTo(Referrals.PendingEligibilityForecastStatus.inProgress)
        #expect(item.status == Referrals.PendingEligibilityForecastStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingEligibilityForecast("code-668", label: "label-894")
        item.status = Referrals.PendingEligibilityForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingEligibilityForecastStatus.planned) }
    }
}
