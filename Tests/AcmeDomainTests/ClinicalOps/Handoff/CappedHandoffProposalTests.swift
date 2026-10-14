@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffProposalTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCappedHandoffProposal("code-219", title: "title-842")
        #expect(item.status == ClinicalOps.CappedHandoffProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newCappedHandoffProposal("code-219", title: "title-842")
        try item.moveTo(ClinicalOps.CappedHandoffProposalStatus.inReview)
        #expect(item.status == ClinicalOps.CappedHandoffProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCappedHandoffProposal("code-219", title: "title-842")
        item.status = ClinicalOps.CappedHandoffProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedHandoffProposalStatus.`open`) }
    }
}
