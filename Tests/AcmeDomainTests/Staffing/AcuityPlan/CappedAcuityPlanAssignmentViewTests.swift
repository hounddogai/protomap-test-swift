@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        let view = Staffing.toCappedAcuityPlanAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedAcuityPlanAssignmentViews([item, item]).count == 2)
    }
}
