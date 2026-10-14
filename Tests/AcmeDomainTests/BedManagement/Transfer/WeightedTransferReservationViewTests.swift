@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newWeightedTransferReservation("code-936", title: "title-842")
        let view = BedManagement.toWeightedTransferReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toWeightedTransferReservationViews([item, item]).count == 2)
    }
}
