@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreCheckpointTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newPendingRiskScoreCheckpoint("code-746", label: "label-376")
        #expect(item.status == CareManagement.PendingRiskScoreCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newPendingRiskScoreCheckpoint("code-746", label: "label-376")
        try item.moveTo(CareManagement.PendingRiskScoreCheckpointStatus.warming)
        #expect(item.status == CareManagement.PendingRiskScoreCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newPendingRiskScoreCheckpoint("code-746", label: "label-376")
        item.status = CareManagement.PendingRiskScoreCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingRiskScoreCheckpointStatus.idle) }
    }
}
