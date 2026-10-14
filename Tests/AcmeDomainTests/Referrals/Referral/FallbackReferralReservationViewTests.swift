@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackReferralReservation("code-61", label: "label-959")
        let view = Referrals.toFallbackReferralReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackReferralReservationViews([item, item]).count == 2)
    }
}
