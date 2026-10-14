@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredFollowUpReservation("code-173", label: "label-886")
        let view = Referrals.toTieredFollowUpReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredFollowUpReservationViews([item, item]).count == 2)
    }
}
