@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralBudget("code-440", title: "title-459")
        let view = Referrals.toReferralBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralBudgetViews([item, item]).count == 2)
    }
}
