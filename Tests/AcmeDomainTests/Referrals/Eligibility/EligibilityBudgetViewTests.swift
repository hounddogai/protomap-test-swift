@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityBudget("code-631", name: "name-381")
        let view = Referrals.toEligibilityBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityBudgetViews([item, item]).count == 2)
    }
}
