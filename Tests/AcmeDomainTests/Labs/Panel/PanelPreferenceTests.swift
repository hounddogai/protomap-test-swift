@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelPreference("code-189", title: "title-112")
        #expect(item.status == Labs.PanelPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newPanelPreference("code-189", title: "title-112")
        try item.moveTo(Labs.PanelPreferenceStatus.closed)
        #expect(item.status == Labs.PanelPreferenceStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelPreference("code-189", title: "title-112")
        item.status = Labs.PanelPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelPreferenceStatus.draft) }
    }
}
