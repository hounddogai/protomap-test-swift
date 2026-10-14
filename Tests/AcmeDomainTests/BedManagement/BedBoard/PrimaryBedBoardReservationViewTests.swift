@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryBedBoardReservation("code-242", name: "name-415")
        let view = BedManagement.toPrimaryBedBoardReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryBedBoardReservationViews([item, item]).count == 2)
    }
}
