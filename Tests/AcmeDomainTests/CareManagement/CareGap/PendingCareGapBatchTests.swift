@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapBatchTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingCareGapBatch("code-442", label: "label-568")
        #expect(item.status == CareManagement.PendingCareGapBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newPendingCareGapBatch("code-442", label: "label-568")
        try item.moveTo(CareManagement.PendingCareGapBatchStatus.approved)
        #expect(item.status == CareManagement.PendingCareGapBatchStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingCareGapBatch("code-442", label: "label-568")
        item.status = CareManagement.PendingCareGapBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingCareGapBatchStatus.proposed) }
    }
}
