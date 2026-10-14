@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilitySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        let view = Referrals.toStrictEligibilitySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictEligibilitySlotViews([item, item]).count == 2)
    }
}
