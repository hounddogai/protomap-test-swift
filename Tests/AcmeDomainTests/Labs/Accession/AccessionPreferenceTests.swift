@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionPreference("code-285", title: "title-486")
        #expect(item.status == Labs.AccessionPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newAccessionPreference("code-285", title: "title-486")
        try item.moveTo(Labs.AccessionPreferenceStatus.suspended)
        #expect(item.status == Labs.AccessionPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionPreference("code-285", title: "title-486")
        item.status = Labs.AccessionPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionPreferenceStatus.draft) }
    }
}
