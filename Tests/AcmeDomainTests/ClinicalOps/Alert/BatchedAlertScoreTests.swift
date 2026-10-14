@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedAlertScoreTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newBatchedAlertScore("code-581", title: "title-91")
        #expect(item.status == ClinicalOps.BatchedAlertScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newBatchedAlertScore("code-581", title: "title-91")
        try item.moveTo(ClinicalOps.BatchedAlertScoreStatus.suspended)
        #expect(item.status == ClinicalOps.BatchedAlertScoreStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newBatchedAlertScore("code-581", title: "title-91")
        item.status = ClinicalOps.BatchedAlertScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedAlertScoreStatus.draft) }
    }
}
