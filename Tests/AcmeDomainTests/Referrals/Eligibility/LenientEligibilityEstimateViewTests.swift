@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilityEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        let view = Referrals.toLenientEligibilityEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientEligibilityEstimateViews([item, item]).count == 2)
    }
}
