@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalClosureRule("code-497", label: "label-382")
        let view = Referrals.toSeasonalClosureRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalClosureRuleViews([item, item]).count == 2)
    }
}
