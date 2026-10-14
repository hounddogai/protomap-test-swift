@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkRollup("code-914", name: "name-924")
        let view = Referrals.toNetworkRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkRollupViews([item, item]).count == 2)
    }
}
