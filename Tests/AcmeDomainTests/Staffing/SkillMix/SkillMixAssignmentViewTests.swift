@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixAssignment("code-888", name: "name-922")
        let view = Staffing.toSkillMixAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixAssignmentViews([item, item]).count == 2)
    }
}
