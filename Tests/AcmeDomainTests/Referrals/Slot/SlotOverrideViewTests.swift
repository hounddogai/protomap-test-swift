@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotOverride("code-916", title: "title-359")
        let view = Referrals.toSlotOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotOverrideViews([item, item]).count == 2)
    }
}
