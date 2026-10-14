@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadProposalTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPendingReadProposal("code-392", label: "label-981")
        #expect(item.status == Imaging.PendingReadProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newPendingReadProposal("code-392", label: "label-981")
        try item.moveTo(Imaging.PendingReadProposalStatus.inReview)
        #expect(item.status == Imaging.PendingReadProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPendingReadProposal("code-392", label: "label-981")
        item.status = Imaging.PendingReadProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingReadProposalStatus.`open`) }
    }
}
