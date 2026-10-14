@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualFollowUpRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualFollowUpRule("code-593", name: "name-303")
        let view = Referrals.toManualFollowUpRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualFollowUpRuleViews([item, item]).count == 2)
    }
}
