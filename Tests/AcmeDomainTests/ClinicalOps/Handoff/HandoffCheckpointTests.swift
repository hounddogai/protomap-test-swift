@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffCheckpoint("code-710", title: "title-681")
        #expect(item.status == ClinicalOps.HandoffCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newHandoffCheckpoint("code-710", title: "title-681")
        try item.moveTo(ClinicalOps.HandoffCheckpointStatus.completed)
        #expect(item.status == ClinicalOps.HandoffCheckpointStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffCheckpoint("code-710", title: "title-681")
        item.status = ClinicalOps.HandoffCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffCheckpointStatus.planned) }
    }
}
