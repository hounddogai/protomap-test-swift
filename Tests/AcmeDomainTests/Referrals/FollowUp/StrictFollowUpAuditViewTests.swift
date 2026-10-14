@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictFollowUpAudit("code-40", title: "title-223")
        let view = Referrals.toStrictFollowUpAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictFollowUpAuditViews([item, item]).count == 2)
    }
}
