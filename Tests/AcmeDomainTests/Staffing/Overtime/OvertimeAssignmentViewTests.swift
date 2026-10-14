@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeAssignment("code-858", name: "name-595")
        let view = Staffing.toOvertimeAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeAssignmentViews([item, item]).count == 2)
    }
}
