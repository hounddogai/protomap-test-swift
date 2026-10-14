@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyProposalTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newStudyProposal("code-944", title: "title-120")
        #expect(item.status == Imaging.StudyProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newStudyProposal("code-944", title: "title-120")
        try item.moveTo(Imaging.StudyProposalStatus.closed)
        #expect(item.status == Imaging.StudyProposalStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newStudyProposal("code-944", title: "title-120")
        item.status = Imaging.StudyProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyProposalStatus.draft) }
    }
}
