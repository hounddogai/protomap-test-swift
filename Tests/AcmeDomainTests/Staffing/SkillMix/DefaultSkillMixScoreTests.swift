@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixScoreTests {
    @Test func startsInNew() throws {
        let item = Staffing.newDefaultSkillMixScore("code-644", title: "title-260")
        #expect(item.status == Staffing.DefaultSkillMixScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newDefaultSkillMixScore("code-644", title: "title-260")
        try item.moveTo(Staffing.DefaultSkillMixScoreStatus.queued)
        #expect(item.status == Staffing.DefaultSkillMixScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newDefaultSkillMixScore("code-644", title: "title-260")
        item.status = Staffing.DefaultSkillMixScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultSkillMixScoreStatus.new) }
    }
}
