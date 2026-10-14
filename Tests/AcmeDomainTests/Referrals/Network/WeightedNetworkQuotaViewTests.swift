@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedNetworkQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedNetworkQuota("code-273", name: "name-30")
        let view = Referrals.toWeightedNetworkQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedNetworkQuotaViews([item, item]).count == 2)
    }
}
