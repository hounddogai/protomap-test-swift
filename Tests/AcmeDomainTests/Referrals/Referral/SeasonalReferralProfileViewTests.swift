@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalReferralProfile("code-21", label: "label-985")
        let view = Referrals.toSeasonalReferralProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalReferralProfileViews([item, item]).count == 2)
    }
}
