@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientFollowUpTarget("code-543", title: "title-986")
        let view = Referrals.toLenientFollowUpTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientFollowUpTargetViews([item, item]).count == 2)
    }
}
