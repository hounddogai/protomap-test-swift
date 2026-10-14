@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionDraftTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionDraft("code-28", name: "name-487")
        #expect(item.status == Labs.AccessionDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newAccessionDraft("code-28", name: "name-487")
        try item.moveTo(Labs.AccessionDraftStatus.stopped)
        #expect(item.status == Labs.AccessionDraftStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionDraft("code-28", name: "name-487")
        item.status = Labs.AccessionDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionDraftStatus.idle) }
    }
}
