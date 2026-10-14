@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredReferralDigest("code-653", title: "title-813")
        let view = Referrals.toTieredReferralDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredReferralDigestViews([item, item]).count == 2)
    }
}
