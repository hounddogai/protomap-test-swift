@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureScore("code-960", title: "title-968")
        let view = Referrals.toClosureScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureScoreViews([item, item]).count == 2)
    }
}
