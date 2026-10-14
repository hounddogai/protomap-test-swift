@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityPlan("code-673", title: "title-637")
        let view = Referrals.toEligibilityPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityPlanViews([item, item]).count == 2)
    }
}
