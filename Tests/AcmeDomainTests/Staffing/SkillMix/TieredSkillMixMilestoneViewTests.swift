@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredSkillMixMilestone("code-543", title: "title-7")
        let view = Staffing.toTieredSkillMixMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredSkillMixMilestoneViews([item, item]).count == 2)
    }
}
