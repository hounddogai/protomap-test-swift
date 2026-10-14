@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedRoundingMappingTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newBatchedRoundingMapping("code-211", name: "name-659")
        #expect(item.status == ClinicalOps.BatchedRoundingMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newBatchedRoundingMapping("code-211", name: "name-659")
        try item.moveTo(ClinicalOps.BatchedRoundingMappingStatus.approved)
        #expect(item.status == ClinicalOps.BatchedRoundingMappingStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newBatchedRoundingMapping("code-211", name: "name-659")
        item.status = ClinicalOps.BatchedRoundingMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedRoundingMappingStatus.proposed) }
    }
}
