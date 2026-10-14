@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftSchedule("code-889", label: "label-320")
        let view = Staffing.toShiftScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftScheduleViews([item, item]).count == 2)
    }
}
