@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingCheckpointTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        #expect(item.status == ClinicalOps.SeasonalRoundingCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        try item.moveTo(ClinicalOps.SeasonalRoundingCheckpointStatus.validated)
        #expect(item.status == ClinicalOps.SeasonalRoundingCheckpointStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        item.status = ClinicalOps.SeasonalRoundingCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalRoundingCheckpointStatus.created) }
    }
}
