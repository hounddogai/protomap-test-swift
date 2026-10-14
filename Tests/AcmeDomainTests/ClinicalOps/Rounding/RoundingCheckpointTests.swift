@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingCheckpointTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRoundingCheckpoint("code-787", label: "label-25")
        #expect(item.status == ClinicalOps.RoundingCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRoundingCheckpoint("code-787", label: "label-25")
        try item.moveTo(ClinicalOps.RoundingCheckpointStatus.revoked)
        #expect(item.status == ClinicalOps.RoundingCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRoundingCheckpoint("code-787", label: "label-25")
        item.status = ClinicalOps.RoundingCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingCheckpointStatus.requested) }
    }
}
