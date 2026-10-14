@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultReservation("code-473", label: "label-803")
        let view = Labs.toResultReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultReservationViews([item, item]).count == 2)
    }
}
