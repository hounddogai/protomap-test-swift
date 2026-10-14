@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskRequestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newTaskRequest("code-460", name: "name-189")
        #expect(item.status == ClinicalOps.TaskRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newTaskRequest("code-460", name: "name-189")
        try item.moveTo(ClinicalOps.TaskRequestStatus.active)
        #expect(item.status == ClinicalOps.TaskRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newTaskRequest("code-460", name: "name-189")
        item.status = ClinicalOps.TaskRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskRequestStatus.draft) }
    }
}
