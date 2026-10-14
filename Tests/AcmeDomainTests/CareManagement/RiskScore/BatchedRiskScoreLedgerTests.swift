@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreLedgerTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newBatchedRiskScoreLedger("code-897", label: "label-875")
        #expect(item.status == CareManagement.BatchedRiskScoreLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newBatchedRiskScoreLedger("code-897", label: "label-875")
        try item.moveTo(CareManagement.BatchedRiskScoreLedgerStatus.rejected)
        #expect(item.status == CareManagement.BatchedRiskScoreLedgerStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newBatchedRiskScoreLedger("code-897", label: "label-875")
        item.status = CareManagement.BatchedRiskScoreLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedRiskScoreLedgerStatus.proposed) }
    }
}
