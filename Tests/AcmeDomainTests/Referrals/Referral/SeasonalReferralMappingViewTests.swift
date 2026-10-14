@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalReferralMapping("code-526", label: "label-297")
        let view = Referrals.toSeasonalReferralMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalReferralMappingViews([item, item]).count == 2)
    }
}
