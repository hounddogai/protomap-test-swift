@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedClosureAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedClosureAdjustment("code-461", name: "name-520")
        let view = Referrals.toWeightedClosureAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedClosureAdjustmentViews([item, item]).count == 2)
    }
}
