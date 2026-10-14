@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimaryClosureForecast("code-66", label: "label-259")
        let view = Referrals.toPrimaryClosureForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimaryClosureForecastViews([item, item]).count == 2)
    }
}
