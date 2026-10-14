@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityForecast("code-703", label: "label-903")
        let view = Referrals.toEligibilityForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityForecastViews([item, item]).count == 2)
    }
}
