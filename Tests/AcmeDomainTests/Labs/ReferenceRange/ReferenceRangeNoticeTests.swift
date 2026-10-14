@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeNoticeTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeNotice("code-746", label: "label-661")
        #expect(item.status == Labs.ReferenceRangeNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newReferenceRangeNotice("code-746", label: "label-661")
        try item.moveTo(Labs.ReferenceRangeNoticeStatus.stopped)
        #expect(item.status == Labs.ReferenceRangeNoticeStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeNotice("code-746", label: "label-661")
        item.status = Labs.ReferenceRangeNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeNoticeStatus.idle) }
    }
}
