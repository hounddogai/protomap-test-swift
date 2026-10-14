@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        let view = Referrals.toLegacyFollowUpAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyFollowUpAuditViews([item, item]).count == 2)
    }
}
