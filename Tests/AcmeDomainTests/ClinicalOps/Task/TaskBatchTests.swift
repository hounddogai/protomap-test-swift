@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskBatchTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTaskBatch("code-546", name: "name-295")
        #expect(item.status == ClinicalOps.TaskBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newTaskBatch("code-546", name: "name-295")
        try item.moveTo(ClinicalOps.TaskBatchStatus.published)
        #expect(item.status == ClinicalOps.TaskBatchStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTaskBatch("code-546", name: "name-295")
        item.status = ClinicalOps.TaskBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskBatchStatus.created) }
    }
}
