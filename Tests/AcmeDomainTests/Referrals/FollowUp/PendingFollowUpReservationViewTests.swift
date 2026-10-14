@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingFollowUpReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingFollowUpReservation("code-375", label: "label-87")
        let view = Referrals.toPendingFollowUpReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingFollowUpReservationViews([item, item]).count == 2)
    }
}
