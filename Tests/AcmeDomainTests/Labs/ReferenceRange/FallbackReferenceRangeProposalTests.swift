@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeProposalTests {
    @Test func startsInOpen() throws {
        let item = Labs.newFallbackReferenceRangeProposal("code-234", name: "name-396")
        #expect(item.status == Labs.FallbackReferenceRangeProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newFallbackReferenceRangeProposal("code-234", name: "name-396")
        try item.moveTo(Labs.FallbackReferenceRangeProposalStatus.reopened)
        #expect(item.status == Labs.FallbackReferenceRangeProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newFallbackReferenceRangeProposal("code-234", name: "name-396")
        item.status = Labs.FallbackReferenceRangeProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackReferenceRangeProposalStatus.`open`) }
    }
}
