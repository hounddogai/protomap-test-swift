@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalFollowUpBaseline("code-871", label: "label-438")
        let view = Referrals.toGlobalFollowUpBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalFollowUpBaselineViews([item, item]).count == 2)
    }
}
