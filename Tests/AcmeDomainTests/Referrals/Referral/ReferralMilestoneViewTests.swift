@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralMilestone("code-390", name: "name-942")
        let view = Referrals.toReferralMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralMilestoneViews([item, item]).count == 2)
    }
}
