@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingSlotRollup("code-688", label: "label-355")
        let view = Referrals.toRollingSlotRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingSlotRollupViews([item, item]).count == 2)
    }
}
