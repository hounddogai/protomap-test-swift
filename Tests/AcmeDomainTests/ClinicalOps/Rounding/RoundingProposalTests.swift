@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingProposalTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRoundingProposal("code-780", name: "name-362")
        #expect(item.status == ClinicalOps.RoundingProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRoundingProposal("code-780", name: "name-362")
        try item.moveTo(ClinicalOps.RoundingProposalStatus.revoked)
        #expect(item.status == ClinicalOps.RoundingProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRoundingProposal("code-780", name: "name-362")
        item.status = ClinicalOps.RoundingProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingProposalStatus.requested) }
    }
}
