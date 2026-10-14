@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpTier("code-428", label: "label-176")
        let view = Referrals.toFollowUpTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpTierViews([item, item]).count == 2)
    }
}
