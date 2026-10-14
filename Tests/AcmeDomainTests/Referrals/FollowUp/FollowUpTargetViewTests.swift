@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpTarget("code-900", name: "name-319")
        let view = Referrals.toFollowUpTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpTargetViews([item, item]).count == 2)
    }
}
