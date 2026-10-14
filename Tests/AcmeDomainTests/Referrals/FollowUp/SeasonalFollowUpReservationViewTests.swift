@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalFollowUpReservation("code-712", name: "name-633")
        let view = Referrals.toSeasonalFollowUpReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalFollowUpReservationViews([item, item]).count == 2)
    }
}
