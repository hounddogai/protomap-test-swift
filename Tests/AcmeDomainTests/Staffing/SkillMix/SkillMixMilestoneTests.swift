@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newSkillMixMilestone("code-712", title: "title-771")
        #expect(item.status == Staffing.SkillMixMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newSkillMixMilestone("code-712", title: "title-771")
        try item.moveTo(Staffing.SkillMixMilestoneStatus.inReview)
        #expect(item.status == Staffing.SkillMixMilestoneStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newSkillMixMilestone("code-712", title: "title-771")
        item.status = Staffing.SkillMixMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixMilestoneStatus.`open`) }
    }
}
