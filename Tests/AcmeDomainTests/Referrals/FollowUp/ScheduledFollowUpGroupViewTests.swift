@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledFollowUpGroup("code-413", name: "name-330")
        let view = Referrals.toScheduledFollowUpGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledFollowUpGroupViews([item, item]).count == 2)
    }
}
