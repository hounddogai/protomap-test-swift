@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixCheckpointTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCappedSkillMixCheckpoint("code-930", name: "name-462")
        #expect(item.status == Staffing.CappedSkillMixCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCappedSkillMixCheckpoint("code-930", name: "name-462")
        try item.moveTo(Staffing.CappedSkillMixCheckpointStatus.approved)
        #expect(item.status == Staffing.CappedSkillMixCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCappedSkillMixCheckpoint("code-930", name: "name-462")
        item.status = Staffing.CappedSkillMixCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixCheckpointStatus.proposed) }
    }
}
