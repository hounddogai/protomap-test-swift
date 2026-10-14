@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotAudit("code-859", label: "label-139")
        let view = Referrals.toSlotAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotAuditViews([item, item]).count == 2)
    }
}
