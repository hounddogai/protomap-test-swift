@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredEligibilityTemplate("code-655", label: "label-117")
        let view = Referrals.toTieredEligibilityTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredEligibilityTemplateViews([item, item]).count == 2)
    }
}
