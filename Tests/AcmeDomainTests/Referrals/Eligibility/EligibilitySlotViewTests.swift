@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilitySlot("code-648", name: "name-217")
        let view = Referrals.toEligibilitySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilitySlotViews([item, item]).count == 2)
    }
}
