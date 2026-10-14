@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        let view = Referrals.toManualNetworkMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualNetworkMilestoneViews([item, item]).count == 2)
    }
}
