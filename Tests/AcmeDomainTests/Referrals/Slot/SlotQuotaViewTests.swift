@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotQuota("code-480", title: "title-671")
        let view = Referrals.toSlotQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotQuotaViews([item, item]).count == 2)
    }
}
