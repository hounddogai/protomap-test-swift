@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientTaskProposalTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newLenientTaskProposal("code-873", label: "label-173")
        #expect(item.status == ClinicalOps.LenientTaskProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newLenientTaskProposal("code-873", label: "label-173")
        try item.moveTo(ClinicalOps.LenientTaskProposalStatus.approved)
        #expect(item.status == ClinicalOps.LenientTaskProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newLenientTaskProposal("code-873", label: "label-173")
        item.status = ClinicalOps.LenientTaskProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientTaskProposalStatus.proposed) }
    }
}
