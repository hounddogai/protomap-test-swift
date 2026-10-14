@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualNetworkForecast("code-999", name: "name-111")
        let view = Referrals.toManualNetworkForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualNetworkForecastViews([item, item]).count == 2)
    }
}
