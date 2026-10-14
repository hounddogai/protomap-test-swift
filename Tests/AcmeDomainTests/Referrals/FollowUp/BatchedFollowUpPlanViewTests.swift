@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedFollowUpPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedFollowUpPlan("code-207", title: "title-690")
        let view = Referrals.toBatchedFollowUpPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedFollowUpPlanViews([item, item]).count == 2)
    }
}
