@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskProposalTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newBatchedTaskProposal("code-436", label: "label-480")
        #expect(item.status == ClinicalOps.BatchedTaskProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newBatchedTaskProposal("code-436", label: "label-480")
        try item.moveTo(ClinicalOps.BatchedTaskProposalStatus.suspended)
        #expect(item.status == ClinicalOps.BatchedTaskProposalStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newBatchedTaskProposal("code-436", label: "label-480")
        item.status = ClinicalOps.BatchedTaskProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedTaskProposalStatus.draft) }
    }
}
