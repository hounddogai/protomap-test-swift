@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredNetworkEntry("code-889", title: "title-356")
        let view = Referrals.toTieredNetworkEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredNetworkEntryViews([item, item]).count == 2)
    }
}
