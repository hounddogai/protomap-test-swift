@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingNetworkBundle("code-969", name: "name-442")
        let view = Referrals.toPendingNetworkBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingNetworkBundleViews([item, item]).count == 2)
    }
}
