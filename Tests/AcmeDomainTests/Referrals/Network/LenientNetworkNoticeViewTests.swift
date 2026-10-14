@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientNetworkNotice("code-131", title: "title-785")
        let view = Referrals.toLenientNetworkNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientNetworkNoticeViews([item, item]).count == 2)
    }
}
