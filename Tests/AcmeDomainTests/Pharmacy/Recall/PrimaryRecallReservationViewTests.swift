@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryRecallReservation("code-3", label: "label-363")
        let view = Pharmacy.toPrimaryRecallReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryRecallReservationViews([item, item]).count == 2)
    }
}
