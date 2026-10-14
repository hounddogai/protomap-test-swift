@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalSlotAdjustment("code-586", label: "label-624")
        let view = Referrals.toGlobalSlotAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalSlotAdjustmentViews([item, item]).count == 2)
    }
}
