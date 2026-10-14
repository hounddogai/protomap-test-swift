@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingEligibilityForecast("code-668", label: "label-894")
        let view = Referrals.toPendingEligibilityForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingEligibilityForecastViews([item, item]).count == 2)
    }
}
