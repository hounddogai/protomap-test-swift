@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskProposalTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newDefaultTaskProposal("code-658", label: "label-357")
        #expect(item.status == ClinicalOps.DefaultTaskProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newDefaultTaskProposal("code-658", label: "label-357")
        try item.moveTo(ClinicalOps.DefaultTaskProposalStatus.rejected)
        #expect(item.status == ClinicalOps.DefaultTaskProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newDefaultTaskProposal("code-658", label: "label-357")
        item.status = ClinicalOps.DefaultTaskProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultTaskProposalStatus.proposed) }
    }
}
