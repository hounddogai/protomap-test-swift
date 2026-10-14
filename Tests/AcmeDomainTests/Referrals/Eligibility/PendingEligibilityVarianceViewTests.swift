@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingEligibilityVariance("code-970", title: "title-309")
        let view = Referrals.toPendingEligibilityVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingEligibilityVarianceViews([item, item]).count == 2)
    }
}
