@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenProposalTests {
    @Test func startsInNew() throws {
        let item = Labs.newDefaultSpecimenProposal("code-893", name: "name-89")
        #expect(item.status == Labs.DefaultSpecimenProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newDefaultSpecimenProposal("code-893", name: "name-89")
        try item.moveTo(Labs.DefaultSpecimenProposalStatus.queued)
        #expect(item.status == Labs.DefaultSpecimenProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newDefaultSpecimenProposal("code-893", name: "name-89")
        item.status = Labs.DefaultSpecimenProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenProposalStatus.new) }
    }
}
