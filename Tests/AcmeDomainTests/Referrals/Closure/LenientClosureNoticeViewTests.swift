@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientClosureNotice("code-410", title: "title-788")
        let view = Referrals.toLenientClosureNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientClosureNoticeViews([item, item]).count == 2)
    }
}
