@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkScore("code-631", title: "title-810")
        let view = Referrals.toNetworkScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkScoreViews([item, item]).count == 2)
    }
}
