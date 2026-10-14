@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityTarget("code-852", name: "name-47")
        let view = Referrals.toEligibilityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityTargetViews([item, item]).count == 2)
    }
}
