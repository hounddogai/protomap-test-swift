@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProposalTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeProposal("code-658", title: "title-313")
        #expect(item.status == Labs.ReferenceRangeProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newReferenceRangeProposal("code-658", title: "title-313")
        try item.moveTo(Labs.ReferenceRangeProposalStatus.pending)
        #expect(item.status == Labs.ReferenceRangeProposalStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeProposal("code-658", title: "title-313")
        item.status = Labs.ReferenceRangeProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeProposalStatus.draft) }
    }
}
