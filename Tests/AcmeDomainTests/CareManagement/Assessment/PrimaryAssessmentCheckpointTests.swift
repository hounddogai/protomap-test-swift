@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentCheckpointTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newPrimaryAssessmentCheckpoint("code-282", name: "name-215")
        #expect(item.status == CareManagement.PrimaryAssessmentCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newPrimaryAssessmentCheckpoint("code-282", name: "name-215")
        try item.moveTo(CareManagement.PrimaryAssessmentCheckpointStatus.running)
        #expect(item.status == CareManagement.PrimaryAssessmentCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newPrimaryAssessmentCheckpoint("code-282", name: "name-215")
        item.status = CareManagement.PrimaryAssessmentCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryAssessmentCheckpointStatus.new) }
    }
}
