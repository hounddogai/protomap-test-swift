@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedHandoffWindowTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newBatchedHandoffWindow("code-104", title: "title-202")
        #expect(item.status == ClinicalOps.BatchedHandoffWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newBatchedHandoffWindow("code-104", title: "title-202")
        try item.moveTo(ClinicalOps.BatchedHandoffWindowStatus.scheduled)
        #expect(item.status == ClinicalOps.BatchedHandoffWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newBatchedHandoffWindow("code-104", title: "title-202")
        item.status = ClinicalOps.BatchedHandoffWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedHandoffWindowStatus.planned) }
    }
}
