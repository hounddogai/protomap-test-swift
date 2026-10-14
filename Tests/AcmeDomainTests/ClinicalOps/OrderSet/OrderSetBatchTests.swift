@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetBatchTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newOrderSetBatch("code-87", name: "name-416")
        #expect(item.status == ClinicalOps.OrderSetBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newOrderSetBatch("code-87", name: "name-416")
        try item.moveTo(ClinicalOps.OrderSetBatchStatus.inReview)
        #expect(item.status == ClinicalOps.OrderSetBatchStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newOrderSetBatch("code-87", name: "name-416")
        item.status = ClinicalOps.OrderSetBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetBatchStatus.`open`) }
    }
}
