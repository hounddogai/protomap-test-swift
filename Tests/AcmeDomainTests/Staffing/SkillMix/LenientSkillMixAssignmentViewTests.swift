@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientSkillMixAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientSkillMixAssignment("code-63", title: "title-469")
        let view = Staffing.toLenientSkillMixAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientSkillMixAssignmentViews([item, item]).count == 2)
    }
}
