@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalReferralOverride("code-341", title: "title-67")
        let view = Referrals.toGlobalReferralOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalReferralOverrideViews([item, item]).count == 2)
    }
}
