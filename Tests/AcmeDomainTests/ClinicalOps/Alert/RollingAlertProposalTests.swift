@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertProposalTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRollingAlertProposal("code-312", title: "title-522")
        #expect(item.status == ClinicalOps.RollingAlertProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newRollingAlertProposal("code-312", title: "title-522")
        try item.moveTo(ClinicalOps.RollingAlertProposalStatus.closed)
        #expect(item.status == ClinicalOps.RollingAlertProposalStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRollingAlertProposal("code-312", title: "title-522")
        item.status = ClinicalOps.RollingAlertProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingAlertProposalStatus.draft) }
    }
}
