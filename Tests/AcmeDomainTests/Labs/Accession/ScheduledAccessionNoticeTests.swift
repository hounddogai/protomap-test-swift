@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newScheduledAccessionNotice("code-753", label: "label-608")
        #expect(item.status == Labs.ScheduledAccessionNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newScheduledAccessionNotice("code-753", label: "label-608")
        try item.moveTo(Labs.ScheduledAccessionNoticeStatus.completed)
        #expect(item.status == Labs.ScheduledAccessionNoticeStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newScheduledAccessionNotice("code-753", label: "label-608")
        item.status = Labs.ScheduledAccessionNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledAccessionNoticeStatus.planned) }
    }
}
