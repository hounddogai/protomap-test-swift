@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        let view = Staffing.toBatchedOvertimeReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toBatchedOvertimeReservationViews([item, item]).count == 2)
    }
}
