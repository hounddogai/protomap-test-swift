@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newDefaultNetworkBundle("code-100", title: "title-548")
        let view = Referrals.toDefaultNetworkBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toDefaultNetworkBundleViews([item, item]).count == 2)
    }
}
