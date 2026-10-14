@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskPolicyTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskPolicy("code-690", title: "title-481")
        #expect(item.status == ClinicalOps.TaskPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newTaskPolicy("code-690", title: "title-481")
        try item.moveTo(ClinicalOps.TaskPolicyStatus.queued)
        #expect(item.status == ClinicalOps.TaskPolicyStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskPolicy("code-690", title: "title-481")
        item.status = ClinicalOps.TaskPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskPolicyStatus.new) }
    }
}
