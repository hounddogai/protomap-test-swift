@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpForecastTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpForecast("code-336", title: "title-291")
        #expect(item.status == Referrals.FollowUpForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newFollowUpForecast("code-336", title: "title-291")
        try item.moveTo(Referrals.FollowUpForecastStatus.scheduled)
        #expect(item.status == Referrals.FollowUpForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpForecast("code-336", title: "title-291")
        item.status = Referrals.FollowUpForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpForecastStatus.planned) }
    }
}
