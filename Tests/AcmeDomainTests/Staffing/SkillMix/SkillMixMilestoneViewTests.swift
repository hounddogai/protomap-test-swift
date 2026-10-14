@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixMilestone("code-712", title: "title-771")
        let view = Staffing.toSkillMixMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixMilestoneViews([item, item]).count == 2)
    }
}
