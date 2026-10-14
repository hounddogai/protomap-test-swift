@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskClaimTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newTaskClaim("code-273", name: "name-890")
        #expect(item.status == ClinicalOps.TaskClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newTaskClaim("code-273", name: "name-890")
        try item.moveTo(ClinicalOps.TaskClaimStatus.pending)
        #expect(item.status == ClinicalOps.TaskClaimStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newTaskClaim("code-273", name: "name-890")
        item.status = ClinicalOps.TaskClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskClaimStatus.draft) }
    }
}
