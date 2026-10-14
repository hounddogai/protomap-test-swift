@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackEligibilityPlan("code-207", title: "title-13")
        let view = Referrals.toFallbackEligibilityPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackEligibilityPlanViews([item, item]).count == 2)
    }
}
