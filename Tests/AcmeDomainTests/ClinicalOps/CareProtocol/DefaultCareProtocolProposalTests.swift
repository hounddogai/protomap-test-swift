@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolProposalTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newDefaultCareProtocolProposal("code-916", title: "title-95")
        #expect(item.status == ClinicalOps.DefaultCareProtocolProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newDefaultCareProtocolProposal("code-916", title: "title-95")
        try item.moveTo(ClinicalOps.DefaultCareProtocolProposalStatus.approved)
        #expect(item.status == ClinicalOps.DefaultCareProtocolProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newDefaultCareProtocolProposal("code-916", title: "title-95")
        item.status = ClinicalOps.DefaultCareProtocolProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultCareProtocolProposalStatus.proposed) }
    }
}
