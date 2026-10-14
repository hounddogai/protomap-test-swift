@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        let view = Referrals.toPrimaryEligibilityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimaryEligibilityQuotaViews([item, item]).count == 2)
    }
}
