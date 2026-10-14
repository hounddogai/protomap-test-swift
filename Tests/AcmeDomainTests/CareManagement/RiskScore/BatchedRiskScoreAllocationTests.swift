@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreAllocationTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newBatchedRiskScoreAllocation("code-958", title: "title-125")
        #expect(item.status == CareManagement.BatchedRiskScoreAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newBatchedRiskScoreAllocation("code-958", title: "title-125")
        try item.moveTo(CareManagement.BatchedRiskScoreAllocationStatus.done)
        #expect(item.status == CareManagement.BatchedRiskScoreAllocationStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newBatchedRiskScoreAllocation("code-958", title: "title-125")
        item.status = CareManagement.BatchedRiskScoreAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedRiskScoreAllocationStatus.new) }
    }
}
