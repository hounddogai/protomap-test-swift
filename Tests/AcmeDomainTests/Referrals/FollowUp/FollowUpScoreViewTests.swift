@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpScore("code-740", label: "label-604")
        let view = Referrals.toFollowUpScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpScoreViews([item, item]).count == 2)
    }
}
