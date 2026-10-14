@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixCheckpoint("code-124", title: "title-87")
        #expect(item.status == Staffing.SkillMixCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newSkillMixCheckpoint("code-124", title: "title-87")
        try item.moveTo(Staffing.SkillMixCheckpointStatus.scheduled)
        #expect(item.status == Staffing.SkillMixCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixCheckpoint("code-124", title: "title-87")
        item.status = Staffing.SkillMixCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixCheckpointStatus.planned) }
    }
}
