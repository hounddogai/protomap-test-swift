@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixScoreTests {
    @Test func startsInNew() throws {
        let item = Staffing.newPendingSkillMixScore("code-941", name: "name-701")
        #expect(item.status == Staffing.PendingSkillMixScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newPendingSkillMixScore("code-941", name: "name-701")
        try item.moveTo(Staffing.PendingSkillMixScoreStatus.running)
        #expect(item.status == Staffing.PendingSkillMixScoreStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newPendingSkillMixScore("code-941", name: "name-701")
        item.status = Staffing.PendingSkillMixScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingSkillMixScoreStatus.new) }
    }
}
