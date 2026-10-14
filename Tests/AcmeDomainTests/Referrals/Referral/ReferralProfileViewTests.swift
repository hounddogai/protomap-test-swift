@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralProfile("code-80", label: "label-845")
        let view = Referrals.toReferralProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralProfileViews([item, item]).count == 2)
    }
}
