@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientOvertimeAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientOvertimeAssignment("code-775", title: "title-961")
        let view = Staffing.toLenientOvertimeAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientOvertimeAssignmentViews([item, item]).count == 2)
    }
}
