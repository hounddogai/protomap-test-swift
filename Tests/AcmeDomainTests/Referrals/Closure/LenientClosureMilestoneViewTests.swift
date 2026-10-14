@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientClosureMilestone("code-153", title: "title-178")
        let view = Referrals.toLenientClosureMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientClosureMilestoneViews([item, item]).count == 2)
    }
}
