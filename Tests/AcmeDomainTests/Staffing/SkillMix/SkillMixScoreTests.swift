@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixScoreTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixScore("code-435", name: "name-815")
        #expect(item.status == Staffing.SkillMixScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSkillMixScore("code-435", name: "name-815")
        try item.moveTo(Staffing.SkillMixScoreStatus.pending)
        #expect(item.status == Staffing.SkillMixScoreStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixScore("code-435", name: "name-815")
        item.status = Staffing.SkillMixScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixScoreStatus.draft) }
    }
}
