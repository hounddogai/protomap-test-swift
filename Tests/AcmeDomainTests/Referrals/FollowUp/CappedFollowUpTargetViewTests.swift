@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedFollowUpTarget("code-230", title: "title-79")
        let view = Referrals.toCappedFollowUpTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedFollowUpTargetViews([item, item]).count == 2)
    }
}
