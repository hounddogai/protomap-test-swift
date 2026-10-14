@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpAdjustment("code-908", name: "name-15")
        let view = Referrals.toFollowUpAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpAdjustmentViews([item, item]).count == 2)
    }
}
