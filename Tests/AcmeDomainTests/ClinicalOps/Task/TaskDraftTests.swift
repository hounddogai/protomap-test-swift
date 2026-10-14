@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskDraftTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newTaskDraft("code-572", label: "label-785")
        #expect(item.status == ClinicalOps.TaskDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newTaskDraft("code-572", label: "label-785")
        try item.moveTo(ClinicalOps.TaskDraftStatus.closed)
        #expect(item.status == ClinicalOps.TaskDraftStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newTaskDraft("code-572", label: "label-785")
        item.status = ClinicalOps.TaskDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskDraftStatus.draft) }
    }
}
