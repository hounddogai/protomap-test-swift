@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityOverride("code-502", title: "title-866")
        let view = Referrals.toEligibilityOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityOverrideViews([item, item]).count == 2)
    }
}
