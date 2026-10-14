@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        let view = Referrals.toLenientNetworkScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientNetworkScoreViews([item, item]).count == 2)
    }
}
