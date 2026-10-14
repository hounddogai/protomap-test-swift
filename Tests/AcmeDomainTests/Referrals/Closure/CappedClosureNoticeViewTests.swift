@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedClosureNotice("code-482", name: "name-726")
        let view = Referrals.toCappedClosureNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedClosureNoticeViews([item, item]).count == 2)
    }
}
