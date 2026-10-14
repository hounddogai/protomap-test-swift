@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalRoundingCheckpointTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRegionalRoundingCheckpoint("code-593", label: "label-475")
        #expect(item.status == ClinicalOps.RegionalRoundingCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newRegionalRoundingCheckpoint("code-593", label: "label-475")
        try item.moveTo(ClinicalOps.RegionalRoundingCheckpointStatus.warming)
        #expect(item.status == ClinicalOps.RegionalRoundingCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRegionalRoundingCheckpoint("code-593", label: "label-475")
        item.status = ClinicalOps.RegionalRoundingCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalRoundingCheckpointStatus.idle) }
    }
}
