@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskBatchTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newDefaultTaskBatch("code-987", title: "title-97")
        #expect(item.status == ClinicalOps.DefaultTaskBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newDefaultTaskBatch("code-987", title: "title-97")
        try item.moveTo(ClinicalOps.DefaultTaskBatchStatus.scheduled)
        #expect(item.status == ClinicalOps.DefaultTaskBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newDefaultTaskBatch("code-987", title: "title-97")
        item.status = ClinicalOps.DefaultTaskBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultTaskBatchStatus.planned) }
    }
}
