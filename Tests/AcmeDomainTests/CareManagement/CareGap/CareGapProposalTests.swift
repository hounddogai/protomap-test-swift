@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProposalTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newCareGapProposal("code-812", label: "label-726")
        #expect(item.status == CareManagement.CareGapProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = CareManagement.newCareGapProposal("code-812", label: "label-726")
        try item.moveTo(CareManagement.CareGapProposalStatus.closed)
        #expect(item.status == CareManagement.CareGapProposalStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newCareGapProposal("code-812", label: "label-726")
        item.status = CareManagement.CareGapProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapProposalStatus.draft) }
    }
}
