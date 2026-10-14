@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledFollowUpCycle("code-214", title: "title-525")
        let view = Referrals.toScheduledFollowUpCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledFollowUpCycleViews([item, item]).count == 2)
    }
}
