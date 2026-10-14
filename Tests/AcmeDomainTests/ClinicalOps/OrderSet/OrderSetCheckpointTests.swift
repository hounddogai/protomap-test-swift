@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetCheckpointTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newOrderSetCheckpoint("code-304", title: "title-101")
        #expect(item.status == ClinicalOps.OrderSetCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newOrderSetCheckpoint("code-304", title: "title-101")
        try item.moveTo(ClinicalOps.OrderSetCheckpointStatus.warming)
        #expect(item.status == ClinicalOps.OrderSetCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newOrderSetCheckpoint("code-304", title: "title-101")
        item.status = ClinicalOps.OrderSetCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetCheckpointStatus.idle) }
    }
}
