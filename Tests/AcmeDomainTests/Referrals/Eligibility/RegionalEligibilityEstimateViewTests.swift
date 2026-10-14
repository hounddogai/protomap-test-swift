@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalEligibilityEstimate("code-633", title: "title-532")
        let view = Referrals.toRegionalEligibilityEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalEligibilityEstimateViews([item, item]).count == 2)
    }
}
