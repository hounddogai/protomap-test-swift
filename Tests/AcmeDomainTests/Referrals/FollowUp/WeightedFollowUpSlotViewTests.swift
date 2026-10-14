@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        let view = Referrals.toWeightedFollowUpSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedFollowUpSlotViews([item, item]).count == 2)
    }
}
