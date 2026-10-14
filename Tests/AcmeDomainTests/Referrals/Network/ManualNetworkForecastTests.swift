@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkForecastTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newManualNetworkForecast("code-999", name: "name-111")
        #expect(item.status == Referrals.ManualNetworkForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newManualNetworkForecast("code-999", name: "name-111")
        try item.moveTo(Referrals.ManualNetworkForecastStatus.published)
        #expect(item.status == Referrals.ManualNetworkForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newManualNetworkForecast("code-999", name: "name-111")
        item.status = Referrals.ManualNetworkForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkForecastStatus.created) }
    }
}
