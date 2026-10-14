@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalEligibilityNotice("code-844", title: "title-884")
        let view = Referrals.toRegionalEligibilityNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalEligibilityNoticeViews([item, item]).count == 2)
    }
}
