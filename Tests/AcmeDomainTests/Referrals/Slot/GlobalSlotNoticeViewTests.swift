@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalSlotNotice("code-105", title: "title-167")
        let view = Referrals.toGlobalSlotNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalSlotNoticeViews([item, item]).count == 2)
    }
}
