@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkSlot("code-565", label: "label-41")
        let view = Referrals.toNetworkSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkSlotViews([item, item]).count == 2)
    }
}
