@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertProposalTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAlertProposal("code-677", name: "name-103")
        #expect(item.status == ClinicalOps.AlertProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newAlertProposal("code-677", name: "name-103")
        try item.moveTo(ClinicalOps.AlertProposalStatus.inReview)
        #expect(item.status == ClinicalOps.AlertProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAlertProposal("code-677", name: "name-103")
        item.status = ClinicalOps.AlertProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertProposalStatus.`open`) }
    }
}
