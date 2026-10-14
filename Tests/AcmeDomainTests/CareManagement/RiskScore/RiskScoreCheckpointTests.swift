@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreCheckpointTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRiskScoreCheckpoint("code-476", label: "label-633")
        #expect(item.status == CareManagement.RiskScoreCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newRiskScoreCheckpoint("code-476", label: "label-633")
        try item.moveTo(CareManagement.RiskScoreCheckpointStatus.draining)
        #expect(item.status == CareManagement.RiskScoreCheckpointStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRiskScoreCheckpoint("code-476", label: "label-633")
        item.status = CareManagement.RiskScoreCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreCheckpointStatus.idle) }
    }
}
