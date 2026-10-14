@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierDraftTests {
    @Test func startsInRequested() throws {
        let item = Labs.newFallbackCourierDraft("code-625", label: "label-839")
        #expect(item.status == Labs.FallbackCourierDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newFallbackCourierDraft("code-625", label: "label-839")
        try item.moveTo(Labs.FallbackCourierDraftStatus.granted)
        #expect(item.status == Labs.FallbackCourierDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newFallbackCourierDraft("code-625", label: "label-839")
        item.status = Labs.FallbackCourierDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackCourierDraftStatus.requested) }
    }
}
