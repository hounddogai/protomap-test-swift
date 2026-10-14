@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityProfile("code-879", label: "label-15")
        let view = Referrals.toEligibilityProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityProfileViews([item, item]).count == 2)
    }
}
