@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedClosureMilestone("code-821", name: "name-90")
        let view = Referrals.toCappedClosureMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedClosureMilestoneViews([item, item]).count == 2)
    }
}
