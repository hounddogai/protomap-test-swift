@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpWindow("code-970", title: "title-274")
        let view = Referrals.toFollowUpWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpWindowViews([item, item]).count == 2)
    }
}
