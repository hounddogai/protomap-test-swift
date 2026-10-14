@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProposalTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWeightedModalityProposal("code-108", name: "name-645")
        #expect(item.status == Imaging.WeightedModalityProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newWeightedModalityProposal("code-108", name: "name-645")
        try item.moveTo(Imaging.WeightedModalityProposalStatus.granted)
        #expect(item.status == Imaging.WeightedModalityProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWeightedModalityProposal("code-108", name: "name-645")
        item.status = Imaging.WeightedModalityProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedModalityProposalStatus.requested) }
    }
}
