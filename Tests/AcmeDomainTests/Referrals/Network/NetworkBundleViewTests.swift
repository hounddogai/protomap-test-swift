@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkBundle("code-516", label: "label-393")
        let view = Referrals.toNetworkBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkBundleViews([item, item]).count == 2)
    }
}
