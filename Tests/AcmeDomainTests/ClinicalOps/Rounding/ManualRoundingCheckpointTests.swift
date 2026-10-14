@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualRoundingCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newManualRoundingCheckpoint("code-850", title: "title-631")
        #expect(item.status == ClinicalOps.ManualRoundingCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newManualRoundingCheckpoint("code-850", title: "title-631")
        try item.moveTo(ClinicalOps.ManualRoundingCheckpointStatus.scheduled)
        #expect(item.status == ClinicalOps.ManualRoundingCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newManualRoundingCheckpoint("code-850", title: "title-631")
        item.status = ClinicalOps.ManualRoundingCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualRoundingCheckpointStatus.planned) }
    }
}
