@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralMapping("code-396", name: "name-719")
        let view = Referrals.toReferralMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralMappingViews([item, item]).count == 2)
    }
}
