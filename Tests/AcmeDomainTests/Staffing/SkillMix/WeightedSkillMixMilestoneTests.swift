@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newWeightedSkillMixMilestone("code-69", name: "name-116")
        #expect(item.status == Staffing.WeightedSkillMixMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newWeightedSkillMixMilestone("code-69", name: "name-116")
        try item.moveTo(Staffing.WeightedSkillMixMilestoneStatus.scheduled)
        #expect(item.status == Staffing.WeightedSkillMixMilestoneStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newWeightedSkillMixMilestone("code-69", name: "name-116")
        item.status = Staffing.WeightedSkillMixMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedSkillMixMilestoneStatus.planned) }
    }
}
