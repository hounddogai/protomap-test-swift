@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityQuota("code-390", label: "label-417")
        let view = Referrals.toEligibilityQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityQuotaViews([item, item]).count == 2)
    }
}
