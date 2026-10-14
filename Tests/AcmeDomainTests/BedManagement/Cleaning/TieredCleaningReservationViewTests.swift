@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        let view = BedManagement.toTieredCleaningReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredCleaningReservationViews([item, item]).count == 2)
    }
}
