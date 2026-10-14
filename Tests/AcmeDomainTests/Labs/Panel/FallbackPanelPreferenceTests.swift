@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelPreferenceTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackPanelPreference("code-570", title: "title-387")
        #expect(item.status == Labs.FallbackPanelPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newFallbackPanelPreference("code-570", title: "title-387")
        try item.moveTo(Labs.FallbackPanelPreferenceStatus.validated)
        #expect(item.status == Labs.FallbackPanelPreferenceStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackPanelPreference("code-570", title: "title-387")
        item.status = Labs.FallbackPanelPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackPanelPreferenceStatus.created) }
    }
}
