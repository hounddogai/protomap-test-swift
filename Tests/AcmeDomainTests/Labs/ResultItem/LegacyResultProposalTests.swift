@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultProposalTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLegacyResultProposal("code-508", title: "title-138")
        #expect(item.status == Labs.LegacyResultProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newLegacyResultProposal("code-508", title: "title-138")
        try item.moveTo(Labs.LegacyResultProposalStatus.reopened)
        #expect(item.status == Labs.LegacyResultProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLegacyResultProposal("code-508", title: "title-138")
        item.status = Labs.LegacyResultProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyResultProposalStatus.`open`) }
    }
}
