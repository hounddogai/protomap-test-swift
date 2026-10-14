@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralReservation("code-294", label: "label-571")
        let view = Referrals.toReferralReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralReservationViews([item, item]).count == 2)
    }
}
