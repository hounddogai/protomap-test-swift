@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalNetworkScore("code-738", name: "name-148")
        let view = Referrals.toRegionalNetworkScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalNetworkScoreViews([item, item]).count == 2)
    }
}
