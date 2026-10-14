@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityNoticeTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPendingModalityNotice("code-502", title: "title-298")
        #expect(item.status == Imaging.PendingModalityNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newPendingModalityNotice("code-502", title: "title-298")
        try item.moveTo(Imaging.PendingModalityNoticeStatus.closed)
        #expect(item.status == Imaging.PendingModalityNoticeStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPendingModalityNotice("code-502", title: "title-298")
        item.status = Imaging.PendingModalityNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingModalityNoticeStatus.draft) }
    }
}
