@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultCleaningReservation("code-430", label: "label-518")
        let view = BedManagement.toDefaultCleaningReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultCleaningReservationViews([item, item]).count == 2)
    }
}
