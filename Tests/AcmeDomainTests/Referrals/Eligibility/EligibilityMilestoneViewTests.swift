@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityMilestone("code-224", name: "name-370")
        let view = Referrals.toEligibilityMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityMilestoneViews([item, item]).count == 2)
    }
}
