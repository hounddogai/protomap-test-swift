@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotReservation("code-769", title: "title-71")
        let view = Referrals.toSlotReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotReservationViews([item, item]).count == 2)
    }
}
