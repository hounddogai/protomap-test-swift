@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixScoreTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newPrimarySkillMixScore("code-692", name: "name-555")
        #expect(item.status == Staffing.PrimarySkillMixScoreStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newPrimarySkillMixScore("code-692", name: "name-555")
        try item.moveTo(Staffing.PrimarySkillMixScoreStatus.ready)
        #expect(item.status == Staffing.PrimarySkillMixScoreStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newPrimarySkillMixScore("code-692", name: "name-555")
        item.status = Staffing.PrimarySkillMixScoreStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimarySkillMixScoreStatus.idle) }
    }
}
