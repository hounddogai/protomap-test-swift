@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingFollowUpRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        let view = Referrals.toRollingFollowUpRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingFollowUpRuleViews([item, item]).count == 2)
    }
}
