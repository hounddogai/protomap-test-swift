@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureMilestone("code-19", title: "title-671")
        let view = Referrals.toClosureMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureMilestoneViews([item, item]).count == 2)
    }
}
