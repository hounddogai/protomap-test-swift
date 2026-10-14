@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreCheckpointTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("code-665", name: "name-891")
        #expect(item.status == CareManagement.AdaptiveRiskScoreCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("code-665", name: "name-891")
        try item.moveTo(CareManagement.AdaptiveRiskScoreCheckpointStatus.approved)
        #expect(item.status == CareManagement.AdaptiveRiskScoreCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("code-665", name: "name-891")
        item.status = CareManagement.AdaptiveRiskScoreCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveRiskScoreCheckpointStatus.proposed) }
    }
}
