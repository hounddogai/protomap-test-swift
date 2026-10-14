@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        let view = Staffing.toDefaultSkillMixAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toDefaultSkillMixAssignmentViews([item, item]).count == 2)
    }
}
