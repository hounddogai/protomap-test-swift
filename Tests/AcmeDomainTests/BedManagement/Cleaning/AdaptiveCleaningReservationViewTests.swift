@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveCleaningReservation("code-677", name: "name-118")
        let view = BedManagement.toAdaptiveCleaningReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveCleaningReservationViews([item, item]).count == 2)
    }
}
