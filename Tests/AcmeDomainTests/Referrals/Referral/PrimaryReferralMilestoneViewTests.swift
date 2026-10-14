@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimaryReferralMilestone("code-916", title: "title-17")
        let view = Referrals.toPrimaryReferralMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimaryReferralMilestoneViews([item, item]).count == 2)
    }
}
