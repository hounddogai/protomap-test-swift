@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        let view = Labs.toLenientSpecimenReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientSpecimenReservationViews([item, item]).count == 2)
    }
}
