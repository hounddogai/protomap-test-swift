@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreCheckpointTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        #expect(item.status == CareManagement.FallbackRiskScoreCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        try item.moveTo(CareManagement.FallbackRiskScoreCheckpointStatus.archived)
        #expect(item.status == CareManagement.FallbackRiskScoreCheckpointStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        item.status = CareManagement.FallbackRiskScoreCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackRiskScoreCheckpointStatus.`open`) }
    }
}
