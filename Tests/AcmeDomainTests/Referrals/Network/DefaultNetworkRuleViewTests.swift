@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newDefaultNetworkRule("code-277", label: "label-953")
        let view = Referrals.toDefaultNetworkRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toDefaultNetworkRuleViews([item, item]).count == 2)
    }
}
