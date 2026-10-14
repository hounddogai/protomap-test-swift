@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreProposalTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRiskScoreProposal("code-816", name: "name-959")
        #expect(item.status == CareManagement.RiskScoreProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = CareManagement.newRiskScoreProposal("code-816", name: "name-959")
        try item.moveTo(CareManagement.RiskScoreProposalStatus.cancelled)
        #expect(item.status == CareManagement.RiskScoreProposalStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRiskScoreProposal("code-816", name: "name-959")
        item.status = CareManagement.RiskScoreProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreProposalStatus.planned) }
    }
}
