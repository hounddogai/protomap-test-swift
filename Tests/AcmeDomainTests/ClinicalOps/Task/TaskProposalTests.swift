@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskProposalTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskProposal("code-428", title: "title-161")
        #expect(item.status == ClinicalOps.TaskProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newTaskProposal("code-428", title: "title-161")
        try item.moveTo(ClinicalOps.TaskProposalStatus.scheduled)
        #expect(item.status == ClinicalOps.TaskProposalStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskProposal("code-428", title: "title-161")
        item.status = ClinicalOps.TaskProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskProposalStatus.planned) }
    }
}
