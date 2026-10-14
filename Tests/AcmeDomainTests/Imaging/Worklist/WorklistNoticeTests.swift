@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistNoticeTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWorklistNotice("code-768", name: "name-446")
        #expect(item.status == Imaging.WorklistNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newWorklistNotice("code-768", name: "name-446")
        try item.moveTo(Imaging.WorklistNoticeStatus.queued)
        #expect(item.status == Imaging.WorklistNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWorklistNotice("code-768", name: "name-446")
        item.status = Imaging.WorklistNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistNoticeStatus.new) }
    }
}
