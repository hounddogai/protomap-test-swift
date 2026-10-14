@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        let view = Referrals.toScheduledFollowUpAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledFollowUpAuditViews([item, item]).count == 2)
    }
}
