@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        let view = Referrals.toRegionalNetworkBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalNetworkBundleViews([item, item]).count == 2)
    }
}
