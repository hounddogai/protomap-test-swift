@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkQuota("code-151", title: "title-465")
        let view = Referrals.toNetworkQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkQuotaViews([item, item]).count == 2)
    }
}
