@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralManifest("code-525", name: "name-102")
        let view = Referrals.toReferralManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralManifestViews([item, item]).count == 2)
    }
}
