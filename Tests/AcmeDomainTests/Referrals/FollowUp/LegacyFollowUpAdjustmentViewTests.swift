@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyFollowUpAdjustment("code-854", name: "name-628")
        let view = Referrals.toLegacyFollowUpAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyFollowUpAdjustmentViews([item, item]).count == 2)
    }
}
