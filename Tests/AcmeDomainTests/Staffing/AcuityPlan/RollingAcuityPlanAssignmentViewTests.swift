@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingAcuityPlanAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingAcuityPlanAssignment("code-918", name: "name-634")
        let view = Staffing.toRollingAcuityPlanAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingAcuityPlanAssignmentViews([item, item]).count == 2)
    }
}
