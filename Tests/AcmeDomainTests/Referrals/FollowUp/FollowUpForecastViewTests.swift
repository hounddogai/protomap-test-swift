@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpForecast("code-336", title: "title-291")
        let view = Referrals.toFollowUpForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpForecastViews([item, item]).count == 2)
    }
}
