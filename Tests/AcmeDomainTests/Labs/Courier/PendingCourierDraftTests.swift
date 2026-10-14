@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierDraftTests {
    @Test func startsInNew() throws {
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        #expect(item.status == Labs.PendingCourierDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        try item.moveTo(Labs.PendingCourierDraftStatus.running)
        #expect(item.status == Labs.PendingCourierDraftStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        item.status = Labs.PendingCourierDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingCourierDraftStatus.new) }
    }
}
