@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolProposalTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolProposal("code-130", title: "title-334")
        #expect(item.status == ClinicalOps.CareProtocolProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newCareProtocolProposal("code-130", title: "title-334")
        try item.moveTo(ClinicalOps.CareProtocolProposalStatus.draining)
        #expect(item.status == ClinicalOps.CareProtocolProposalStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolProposal("code-130", title: "title-334")
        item.status = ClinicalOps.CareProtocolProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolProposalStatus.idle) }
    }
}
