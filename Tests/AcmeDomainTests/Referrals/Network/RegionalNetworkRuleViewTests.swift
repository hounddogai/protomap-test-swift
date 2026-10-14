@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalNetworkRule("code-399", title: "title-759")
        let view = Referrals.toRegionalNetworkRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalNetworkRuleViews([item, item]).count == 2)
    }
}
