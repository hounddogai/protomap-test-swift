@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenProposalTests {
    @Test func startsInOpen() throws {
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        #expect(item.status == Labs.WeightedSpecimenProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        try item.moveTo(Labs.WeightedSpecimenProposalStatus.reopened)
        #expect(item.status == Labs.WeightedSpecimenProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        item.status = Labs.WeightedSpecimenProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedSpecimenProposalStatus.`open`) }
    }
}
