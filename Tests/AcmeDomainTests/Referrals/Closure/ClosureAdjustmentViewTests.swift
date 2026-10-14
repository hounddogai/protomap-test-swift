@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureAdjustment("code-528", title: "title-234")
        let view = Referrals.toClosureAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureAdjustmentViews([item, item]).count == 2)
    }
}
