@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffProposalTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newHandoffProposal("code-514", name: "name-566")
        #expect(item.status == ClinicalOps.HandoffProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newHandoffProposal("code-514", name: "name-566")
        try item.moveTo(ClinicalOps.HandoffProposalStatus.inReview)
        #expect(item.status == ClinicalOps.HandoffProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newHandoffProposal("code-514", name: "name-566")
        item.status = ClinicalOps.HandoffProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffProposalStatus.`open`) }
    }
}
