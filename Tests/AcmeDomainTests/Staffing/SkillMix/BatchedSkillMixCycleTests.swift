@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedSkillMixCycleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newBatchedSkillMixCycle("code-713", title: "title-548")
        #expect(item.status == Staffing.BatchedSkillMixCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newBatchedSkillMixCycle("code-713", title: "title-548")
        try item.moveTo(Staffing.BatchedSkillMixCycleStatus.pending)
        #expect(item.status == Staffing.BatchedSkillMixCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newBatchedSkillMixCycle("code-713", title: "title-548")
        item.status = Staffing.BatchedSkillMixCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedSkillMixCycleStatus.draft) }
    }
}
