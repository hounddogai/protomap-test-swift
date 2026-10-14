@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredReferralMilestone("code-613", title: "title-714")
        let view = Referrals.toTieredReferralMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredReferralMilestoneViews([item, item]).count == 2)
    }
}
