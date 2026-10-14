@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPendingCourierPreference("code-97", label: "label-119")
        #expect(item.status == Labs.PendingCourierPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newPendingCourierPreference("code-97", label: "label-119")
        try item.moveTo(Labs.PendingCourierPreferenceStatus.suspended)
        #expect(item.status == Labs.PendingCourierPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPendingCourierPreference("code-97", label: "label-119")
        item.status = Labs.PendingCourierPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingCourierPreferenceStatus.draft) }
    }
}
