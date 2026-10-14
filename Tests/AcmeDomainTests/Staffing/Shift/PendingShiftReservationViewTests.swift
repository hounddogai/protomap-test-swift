@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingShiftReservation("code-545", label: "label-756")
        let view = Staffing.toPendingShiftReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingShiftReservationViews([item, item]).count == 2)
    }
}
