@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledSkillMixEstimateTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newScheduledSkillMixEstimate("code-972", label: "label-44")
        #expect(item.status == Staffing.ScheduledSkillMixEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newScheduledSkillMixEstimate("code-972", label: "label-44")
        try item.moveTo(Staffing.ScheduledSkillMixEstimateStatus.inReview)
        #expect(item.status == Staffing.ScheduledSkillMixEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newScheduledSkillMixEstimate("code-972", label: "label-44")
        item.status = Staffing.ScheduledSkillMixEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledSkillMixEstimateStatus.`open`) }
    }
}
