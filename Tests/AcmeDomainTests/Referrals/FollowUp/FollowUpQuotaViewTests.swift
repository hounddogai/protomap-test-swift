@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpQuota("code-483", label: "label-655")
        let view = Referrals.toFollowUpQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpQuotaViews([item, item]).count == 2)
    }
}
