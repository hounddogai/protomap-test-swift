@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newAdaptiveNetworkBundle("code-457", title: "title-31")
        let view = Referrals.toAdaptiveNetworkBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toAdaptiveNetworkBundleViews([item, item]).count == 2)
    }
}
