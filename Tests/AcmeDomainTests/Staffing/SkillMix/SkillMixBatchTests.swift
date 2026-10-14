@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixBatchTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSkillMixBatch("code-287", title: "title-996")
        #expect(item.status == Staffing.SkillMixBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newSkillMixBatch("code-287", title: "title-996")
        try item.moveTo(Staffing.SkillMixBatchStatus.validated)
        #expect(item.status == Staffing.SkillMixBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSkillMixBatch("code-287", title: "title-996")
        item.status = Staffing.SkillMixBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixBatchStatus.created) }
    }
}
