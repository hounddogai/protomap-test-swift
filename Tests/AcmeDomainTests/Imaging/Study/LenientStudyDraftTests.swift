@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyDraftTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newLenientStudyDraft("code-961", title: "title-313")
        #expect(item.status == Imaging.LenientStudyDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newLenientStudyDraft("code-961", title: "title-313")
        try item.moveTo(Imaging.LenientStudyDraftStatus.closed)
        #expect(item.status == Imaging.LenientStudyDraftStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newLenientStudyDraft("code-961", title: "title-313")
        item.status = Imaging.LenientStudyDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientStudyDraftStatus.draft) }
    }
}
