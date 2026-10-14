@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentCheckpointTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newAssessmentCheckpoint("code-233", name: "name-503")
        #expect(item.status == CareManagement.AssessmentCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newAssessmentCheckpoint("code-233", name: "name-503")
        try item.moveTo(CareManagement.AssessmentCheckpointStatus.done)
        #expect(item.status == CareManagement.AssessmentCheckpointStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newAssessmentCheckpoint("code-233", name: "name-503")
        item.status = CareManagement.AssessmentCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentCheckpointStatus.new) }
    }
}
