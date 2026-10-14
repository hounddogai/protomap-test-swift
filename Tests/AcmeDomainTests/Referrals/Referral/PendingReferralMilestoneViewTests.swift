@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        let view = Referrals.toPendingReferralMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingReferralMilestoneViews([item, item]).count == 2)
    }
}
