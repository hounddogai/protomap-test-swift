@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotNotice("code-464", title: "title-42")
        let view = Referrals.toSlotNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotNoticeViews([item, item]).count == 2)
    }
}
