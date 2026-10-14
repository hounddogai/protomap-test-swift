@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffProposalTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newFallbackHandoffProposal("code-773", name: "name-302")
        #expect(item.status == ClinicalOps.FallbackHandoffProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newFallbackHandoffProposal("code-773", name: "name-302")
        try item.moveTo(ClinicalOps.FallbackHandoffProposalStatus.scheduled)
        #expect(item.status == ClinicalOps.FallbackHandoffProposalStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newFallbackHandoffProposal("code-773", name: "name-302")
        item.status = ClinicalOps.FallbackHandoffProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackHandoffProposalStatus.planned) }
    }
}
