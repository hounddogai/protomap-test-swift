@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetProposalTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetProposal("code-247", name: "name-96")
        #expect(item.status == ClinicalOps.OrderSetProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newOrderSetProposal("code-247", name: "name-96")
        try item.moveTo(ClinicalOps.OrderSetProposalStatus.inProgress)
        #expect(item.status == ClinicalOps.OrderSetProposalStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetProposal("code-247", name: "name-96")
        item.status = ClinicalOps.OrderSetProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetProposalStatus.planned) }
    }
}
