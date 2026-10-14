@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedSkillMixEstimateTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newBatchedSkillMixEstimate("code-217", title: "title-298")
        #expect(item.status == Staffing.BatchedSkillMixEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newBatchedSkillMixEstimate("code-217", title: "title-298")
        try item.moveTo(Staffing.BatchedSkillMixEstimateStatus.granted)
        #expect(item.status == Staffing.BatchedSkillMixEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newBatchedSkillMixEstimate("code-217", title: "title-298")
        item.status = Staffing.BatchedSkillMixEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedSkillMixEstimateStatus.requested) }
    }
}
