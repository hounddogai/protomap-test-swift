@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpBaseline("code-68", title: "title-170")
        let view = Referrals.toFollowUpBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpBaselineViews([item, item]).count == 2)
    }
}
