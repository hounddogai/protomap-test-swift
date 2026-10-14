@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityClaim("code-252", title: "title-920")
        let view = Referrals.toEligibilityClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityClaimViews([item, item]).count == 2)
    }
}
