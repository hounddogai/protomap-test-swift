@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpRollup("code-953", title: "title-781")
        let view = Referrals.toFollowUpRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpRollupViews([item, item]).count == 2)
    }
}
