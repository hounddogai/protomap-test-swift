@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskScoreTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newTaskScore("code-489", name: "name-329")
        #expect(item.status == ClinicalOps.TaskScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newTaskScore("code-489", name: "name-329")
        try item.moveTo(ClinicalOps.TaskScoreStatus.revoked)
        #expect(item.status == ClinicalOps.TaskScoreStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newTaskScore("code-489", name: "name-329")
        item.status = ClinicalOps.TaskScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskScoreStatus.requested) }
    }
}
