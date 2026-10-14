@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newFallbackResultPreference("code-736", title: "title-424")
        #expect(item.status == Labs.FallbackResultPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newFallbackResultPreference("code-736", title: "title-424")
        try item.moveTo(Labs.FallbackResultPreferenceStatus.completed)
        #expect(item.status == Labs.FallbackResultPreferenceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newFallbackResultPreference("code-736", title: "title-424")
        item.status = Labs.FallbackResultPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackResultPreferenceStatus.planned) }
    }
}
