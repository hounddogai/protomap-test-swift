@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreProposalTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newBatchedRiskScoreProposal("code-658", name: "name-526")
        #expect(item.status == CareManagement.BatchedRiskScoreProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newBatchedRiskScoreProposal("code-658", name: "name-526")
        try item.moveTo(CareManagement.BatchedRiskScoreProposalStatus.approved)
        #expect(item.status == CareManagement.BatchedRiskScoreProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newBatchedRiskScoreProposal("code-658", name: "name-526")
        item.status = CareManagement.BatchedRiskScoreProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedRiskScoreProposalStatus.proposed) }
    }
}
