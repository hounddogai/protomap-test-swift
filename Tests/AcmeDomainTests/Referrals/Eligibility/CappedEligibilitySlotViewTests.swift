@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilitySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedEligibilitySlot("code-781", title: "title-927")
        let view = Referrals.toCappedEligibilitySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedEligibilitySlotViews([item, item]).count == 2)
    }
}
