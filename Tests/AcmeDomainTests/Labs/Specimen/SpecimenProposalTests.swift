@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenProposalTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenProposal("code-26", title: "title-736")
        #expect(item.status == Labs.SpecimenProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newSpecimenProposal("code-26", title: "title-736")
        try item.moveTo(Labs.SpecimenProposalStatus.closed)
        #expect(item.status == Labs.SpecimenProposalStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenProposal("code-26", title: "title-736")
        item.status = Labs.SpecimenProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenProposalStatus.draft) }
    }
}
