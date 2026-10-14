@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionPlanTests {
    @Test func startsInNew() throws {
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        #expect(item.status == Labs.BatchedAccessionPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        try item.moveTo(Labs.BatchedAccessionPlanStatus.queued)
        #expect(item.status == Labs.BatchedAccessionPlanStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        item.status = Labs.BatchedAccessionPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedAccessionPlanStatus.new) }
    }
}
