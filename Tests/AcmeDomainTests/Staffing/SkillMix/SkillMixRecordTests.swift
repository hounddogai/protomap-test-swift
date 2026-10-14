@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRecordTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newSkillMixRecord("code-418", title: "title-571")
        #expect(item.status == Staffing.SkillMixRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newSkillMixRecord("code-418", title: "title-571")
        try item.moveTo(Staffing.SkillMixRecordStatus.reopened)
        #expect(item.status == Staffing.SkillMixRecordStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newSkillMixRecord("code-418", title: "title-571")
        item.status = Staffing.SkillMixRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixRecordStatus.`open`) }
    }
}
