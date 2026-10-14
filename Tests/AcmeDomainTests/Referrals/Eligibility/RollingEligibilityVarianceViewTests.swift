@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilityVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        let view = Referrals.toRollingEligibilityVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingEligibilityVarianceViews([item, item]).count == 2)
    }
}
