@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyEligibilityBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyEligibilityBudget("code-129", label: "label-930")
        let view = Referrals.toLegacyEligibilityBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyEligibilityBudgetViews([item, item]).count == 2)
    }
}
