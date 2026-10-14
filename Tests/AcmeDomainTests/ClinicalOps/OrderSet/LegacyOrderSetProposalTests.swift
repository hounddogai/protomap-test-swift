@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetProposalTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newLegacyOrderSetProposal("code-16", label: "label-251")
        #expect(item.status == ClinicalOps.LegacyOrderSetProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newLegacyOrderSetProposal("code-16", label: "label-251")
        try item.moveTo(ClinicalOps.LegacyOrderSetProposalStatus.draining)
        #expect(item.status == ClinicalOps.LegacyOrderSetProposalStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newLegacyOrderSetProposal("code-16", label: "label-251")
        item.status = ClinicalOps.LegacyOrderSetProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyOrderSetProposalStatus.idle) }
    }
}
