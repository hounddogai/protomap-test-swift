@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkTier("code-20", title: "title-847")
        let view = Referrals.toNetworkTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkTierViews([item, item]).count == 2)
    }
}
