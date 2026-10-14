@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictFollowUpAdjustment("code-820", label: "label-705")
        let view = Referrals.toStrictFollowUpAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictFollowUpAdjustmentViews([item, item]).count == 2)
    }
}
