@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityTemplate("code-295", label: "label-307")
        let view = Referrals.toEligibilityTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityTemplateViews([item, item]).count == 2)
    }
}
