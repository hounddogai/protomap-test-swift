@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalSlotOverride("code-748", name: "name-841")
        let view = Referrals.toRegionalSlotOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalSlotOverrideViews([item, item]).count == 2)
    }
}
