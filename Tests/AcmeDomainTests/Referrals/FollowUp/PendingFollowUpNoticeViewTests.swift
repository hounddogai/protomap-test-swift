@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingFollowUpNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingFollowUpNotice("code-18", title: "title-95")
        let view = Referrals.toPendingFollowUpNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingFollowUpNoticeViews([item, item]).count == 2)
    }
}
