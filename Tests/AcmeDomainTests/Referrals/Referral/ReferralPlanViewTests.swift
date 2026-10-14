@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralPlan("code-781", title: "title-629")
        let view = Referrals.toReferralPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralPlanViews([item, item]).count == 2)
    }
}
