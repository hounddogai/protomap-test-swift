@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProposalTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        #expect(item.status == Imaging.WeightedReadProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        try item.moveTo(Imaging.WeightedReadProposalStatus.published)
        #expect(item.status == Imaging.WeightedReadProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        item.status = Imaging.WeightedReadProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedReadProposalStatus.created) }
    }
}
