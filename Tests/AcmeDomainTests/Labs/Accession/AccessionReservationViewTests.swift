@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionReservation("code-978", label: "label-337")
        let view = Labs.toAccessionReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionReservationViews([item, item]).count == 2)
    }
}
