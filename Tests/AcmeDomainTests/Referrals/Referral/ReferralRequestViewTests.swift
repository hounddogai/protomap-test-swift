@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralRequest("code-61", name: "name-936")
        let view = Referrals.toReferralRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralRequestViews([item, item]).count == 2)
    }
}
