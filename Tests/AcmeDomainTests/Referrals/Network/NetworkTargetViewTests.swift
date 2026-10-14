@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkTarget("code-319", name: "name-881")
        let view = Referrals.toNetworkTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkTargetViews([item, item]).count == 2)
    }
}
