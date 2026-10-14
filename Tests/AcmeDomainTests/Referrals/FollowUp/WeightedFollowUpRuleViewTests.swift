@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedFollowUpRule("code-88", label: "label-214")
        let view = Referrals.toWeightedFollowUpRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedFollowUpRuleViews([item, item]).count == 2)
    }
}
