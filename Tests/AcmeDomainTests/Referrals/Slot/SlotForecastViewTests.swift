@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotForecast("code-920", name: "name-661")
        let view = Referrals.toSlotForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotForecastViews([item, item]).count == 2)
    }
}
