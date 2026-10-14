@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedOrderSetPreferenceTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newBatchedOrderSetPreference("code-468", label: "label-878")
        #expect(item.status == ClinicalOps.BatchedOrderSetPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newBatchedOrderSetPreference("code-468", label: "label-878")
        try item.moveTo(ClinicalOps.BatchedOrderSetPreferenceStatus.approved)
        #expect(item.status == ClinicalOps.BatchedOrderSetPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newBatchedOrderSetPreference("code-468", label: "label-878")
        item.status = ClinicalOps.BatchedOrderSetPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedOrderSetPreferenceStatus.proposed) }
    }
}
