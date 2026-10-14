@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyProposalTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newLegacyStudyProposal("code-460", label: "label-813")
        #expect(item.status == Imaging.LegacyStudyProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newLegacyStudyProposal("code-460", label: "label-813")
        try item.moveTo(Imaging.LegacyStudyProposalStatus.inReview)
        #expect(item.status == Imaging.LegacyStudyProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newLegacyStudyProposal("code-460", label: "label-813")
        item.status = Imaging.LegacyStudyProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyStudyProposalStatus.`open`) }
    }
}
