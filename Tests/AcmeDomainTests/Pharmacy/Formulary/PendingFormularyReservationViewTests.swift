@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingFormularyReservation("code-106", name: "name-428")
        let view = Pharmacy.toPendingFormularyReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingFormularyReservationViews([item, item]).count == 2)
    }
}
