@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityRollup("code-507", title: "title-351")
        let view = Referrals.toEligibilityRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityRollupViews([item, item]).count == 2)
    }
}
