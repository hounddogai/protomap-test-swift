@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpNotice("code-495", name: "name-413")
        let view = Referrals.toFollowUpNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpNoticeViews([item, item]).count == 2)
    }
}
