@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadProposalTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newLenientReadProposal("code-677", title: "title-633")
        #expect(item.status == Imaging.LenientReadProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newLenientReadProposal("code-677", title: "title-633")
        try item.moveTo(Imaging.LenientReadProposalStatus.published)
        #expect(item.status == Imaging.LenientReadProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newLenientReadProposal("code-677", title: "title-633")
        item.status = Imaging.LenientReadProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientReadProposalStatus.created) }
    }
}
