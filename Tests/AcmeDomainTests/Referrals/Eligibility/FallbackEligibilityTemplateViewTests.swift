@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackEligibilityTemplate("code-15", label: "label-494")
        let view = Referrals.toFallbackEligibilityTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackEligibilityTemplateViews([item, item]).count == 2)
    }
}
