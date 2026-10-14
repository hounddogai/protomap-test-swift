@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        let view = Referrals.toNetworkOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkOverrideViews([item, item]).count == 2)
    }
}
