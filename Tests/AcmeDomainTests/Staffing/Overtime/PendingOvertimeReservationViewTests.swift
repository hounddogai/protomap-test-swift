@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        let view = Staffing.toPendingOvertimeReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingOvertimeReservationViews([item, item]).count == 2)
    }
}
