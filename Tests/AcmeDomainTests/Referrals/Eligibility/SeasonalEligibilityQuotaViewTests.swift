@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        let view = Referrals.toSeasonalEligibilityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalEligibilityQuotaViews([item, item]).count == 2)
    }
}
