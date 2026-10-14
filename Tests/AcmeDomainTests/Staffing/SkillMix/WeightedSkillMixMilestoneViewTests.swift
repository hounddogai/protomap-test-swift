@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedSkillMixMilestone("code-69", name: "name-116")
        let view = Staffing.toWeightedSkillMixMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedSkillMixMilestoneViews([item, item]).count == 2)
    }
}
