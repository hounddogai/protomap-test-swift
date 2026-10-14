@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkForecastTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkForecast("code-424", title: "title-185")
        #expect(item.status == Referrals.NetworkForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newNetworkForecast("code-424", title: "title-185")
        try item.moveTo(Referrals.NetworkForecastStatus.active)
        #expect(item.status == Referrals.NetworkForecastStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkForecast("code-424", title: "title-185")
        item.status = Referrals.NetworkForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkForecastStatus.draft) }
    }
}
