@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        let view = Referrals.toEligibilityVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityVarianceViews([item, item]).count == 2)
    }
}
