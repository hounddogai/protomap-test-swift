@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedReferralVariance("code-613", name: "name-855")
        let view = Referrals.toWeightedReferralVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedReferralVarianceViews([item, item]).count == 2)
    }
}
