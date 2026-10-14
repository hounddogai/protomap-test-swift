@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotItemViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotItem("code-782", label: "label-562")
        let view = Referrals.toSlotItemView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotItemViews([item, item]).count == 2)
    }
}
