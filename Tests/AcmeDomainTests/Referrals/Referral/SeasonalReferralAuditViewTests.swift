@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalReferralAudit("code-468", label: "label-829")
        let view = Referrals.toSeasonalReferralAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalReferralAuditViews([item, item]).count == 2)
    }
}
