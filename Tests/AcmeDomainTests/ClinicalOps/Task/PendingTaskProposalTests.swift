@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskProposalTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newPendingTaskProposal("code-776", label: "label-775")
        #expect(item.status == ClinicalOps.PendingTaskProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newPendingTaskProposal("code-776", label: "label-775")
        try item.moveTo(ClinicalOps.PendingTaskProposalStatus.scheduled)
        #expect(item.status == ClinicalOps.PendingTaskProposalStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newPendingTaskProposal("code-776", label: "label-775")
        item.status = ClinicalOps.PendingTaskProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingTaskProposalStatus.planned) }
    }
}
