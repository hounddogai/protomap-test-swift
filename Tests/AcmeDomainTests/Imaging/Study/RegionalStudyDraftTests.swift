@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyDraftTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newRegionalStudyDraft("code-383", title: "title-352")
        #expect(item.status == Imaging.RegionalStudyDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newRegionalStudyDraft("code-383", title: "title-352")
        try item.moveTo(Imaging.RegionalStudyDraftStatus.ready)
        #expect(item.status == Imaging.RegionalStudyDraftStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newRegionalStudyDraft("code-383", title: "title-352")
        item.status = Imaging.RegionalStudyDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyDraftStatus.idle) }
    }
}
