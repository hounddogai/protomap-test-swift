@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpReservation("code-579", name: "name-106")
        let view = Referrals.toFollowUpReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpReservationViews([item, item]).count == 2)
    }
}
