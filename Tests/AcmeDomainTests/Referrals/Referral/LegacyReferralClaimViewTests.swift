@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        let view = Referrals.toLegacyReferralClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyReferralClaimViews([item, item]).count == 2)
    }
}
