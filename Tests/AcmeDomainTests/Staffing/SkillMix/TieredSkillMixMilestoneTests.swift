@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newTieredSkillMixMilestone("code-543", title: "title-7")
        #expect(item.status == Staffing.TieredSkillMixMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newTieredSkillMixMilestone("code-543", title: "title-7")
        try item.moveTo(Staffing.TieredSkillMixMilestoneStatus.validated)
        #expect(item.status == Staffing.TieredSkillMixMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newTieredSkillMixMilestone("code-543", title: "title-7")
        item.status = Staffing.TieredSkillMixMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredSkillMixMilestoneStatus.created) }
    }
}
