@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("code-781", label: "label-857")
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("code-781", label: "label-857")
        try item.moveTo(ClinicalOps.AdaptiveCareProtocolProposalStatus.granted)
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("code-781", label: "label-857")
        item.status = ClinicalOps.AdaptiveCareProtocolProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveCareProtocolProposalStatus.requested) }
    }
}
