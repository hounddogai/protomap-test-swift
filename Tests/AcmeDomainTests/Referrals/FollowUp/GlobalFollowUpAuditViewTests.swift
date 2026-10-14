@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalFollowUpAudit("code-54", label: "label-17")
        let view = Referrals.toGlobalFollowUpAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalFollowUpAuditViews([item, item]).count == 2)
    }
}
