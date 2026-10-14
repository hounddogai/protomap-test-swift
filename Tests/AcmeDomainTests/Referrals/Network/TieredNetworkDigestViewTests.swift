@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        let view = Referrals.toTieredNetworkDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredNetworkDigestViews([item, item]).count == 2)
    }
}
