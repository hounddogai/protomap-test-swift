@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryReservation("code-293", label: "label-326")
        let view = Pharmacy.toInventoryReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryReservationViews([item, item]).count == 2)
    }
}
