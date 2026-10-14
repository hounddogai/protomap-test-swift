@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryFollowUpAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        let view = Referrals.toPrimaryFollowUpAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimaryFollowUpAdjustmentViews([item, item]).count == 2)
    }
}
