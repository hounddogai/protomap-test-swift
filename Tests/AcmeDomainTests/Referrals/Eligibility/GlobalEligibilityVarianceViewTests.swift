@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        let view = Referrals.toGlobalEligibilityVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalEligibilityVarianceViews([item, item]).count == 2)
    }
}
