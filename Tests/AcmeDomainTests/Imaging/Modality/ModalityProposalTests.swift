@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityProposalTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newModalityProposal("code-692", name: "name-347")
        #expect(item.status == Imaging.ModalityProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newModalityProposal("code-692", name: "name-347")
        try item.moveTo(Imaging.ModalityProposalStatus.rejected)
        #expect(item.status == Imaging.ModalityProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newModalityProposal("code-692", name: "name-347")
        item.status = Imaging.ModalityProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityProposalStatus.proposed) }
    }
}
