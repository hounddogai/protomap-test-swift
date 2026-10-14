@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedReferralReservation("code-339", title: "title-160")
        let view = Referrals.toWeightedReferralReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedReferralReservationViews([item, item]).count == 2)
    }
}
