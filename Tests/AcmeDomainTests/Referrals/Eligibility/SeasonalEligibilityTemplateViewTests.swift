@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalEligibilityTemplate("code-814", name: "name-994")
        let view = Referrals.toSeasonalEligibilityTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalEligibilityTemplateViews([item, item]).count == 2)
    }
}
