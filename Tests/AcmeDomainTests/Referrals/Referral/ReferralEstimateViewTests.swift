@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralEstimate("code-181", name: "name-719")
        let view = Referrals.toReferralEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralEstimateViews([item, item]).count == 2)
    }
}
