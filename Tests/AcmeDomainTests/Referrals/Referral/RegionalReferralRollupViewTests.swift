@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalReferralRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalReferralRollup("code-996", title: "title-781")
        let view = Referrals.toRegionalReferralRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalReferralRollupViews([item, item]).count == 2)
    }
}
