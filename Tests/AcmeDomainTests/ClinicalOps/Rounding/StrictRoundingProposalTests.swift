@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingProposalTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newStrictRoundingProposal("code-716", title: "title-536")
        #expect(item.status == ClinicalOps.StrictRoundingProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newStrictRoundingProposal("code-716", title: "title-536")
        try item.moveTo(ClinicalOps.StrictRoundingProposalStatus.revoked)
        #expect(item.status == ClinicalOps.StrictRoundingProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newStrictRoundingProposal("code-716", title: "title-536")
        item.status = ClinicalOps.StrictRoundingProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictRoundingProposalStatus.requested) }
    }
}
