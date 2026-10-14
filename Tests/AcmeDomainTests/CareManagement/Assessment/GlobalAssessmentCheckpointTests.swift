@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGlobalAssessmentCheckpoint("code-188", name: "name-577")
        #expect(item.status == CareManagement.GlobalAssessmentCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newGlobalAssessmentCheckpoint("code-188", name: "name-577")
        try item.moveTo(CareManagement.GlobalAssessmentCheckpointStatus.scheduled)
        #expect(item.status == CareManagement.GlobalAssessmentCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGlobalAssessmentCheckpoint("code-188", name: "name-577")
        item.status = CareManagement.GlobalAssessmentCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalAssessmentCheckpointStatus.planned) }
    }
}
