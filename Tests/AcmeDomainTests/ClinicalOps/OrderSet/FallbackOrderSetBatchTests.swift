@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetBatchTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newFallbackOrderSetBatch("code-273", label: "label-769")
        #expect(item.status == ClinicalOps.FallbackOrderSetBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newFallbackOrderSetBatch("code-273", label: "label-769")
        try item.moveTo(ClinicalOps.FallbackOrderSetBatchStatus.inReview)
        #expect(item.status == ClinicalOps.FallbackOrderSetBatchStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newFallbackOrderSetBatch("code-273", label: "label-769")
        item.status = ClinicalOps.FallbackOrderSetBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackOrderSetBatchStatus.`open`) }
    }
}
