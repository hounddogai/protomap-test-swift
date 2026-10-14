@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyPanelThresholdTests {
    @Test func startsInDraft() throws {
        let item = Labs.newLegacyPanelThreshold("code-758", title: "title-623")
        #expect(item.status == Labs.LegacyPanelThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newLegacyPanelThreshold("code-758", title: "title-623")
        try item.moveTo(Labs.LegacyPanelThresholdStatus.active)
        #expect(item.status == Labs.LegacyPanelThresholdStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newLegacyPanelThreshold("code-758", title: "title-623")
        item.status = Labs.LegacyPanelThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyPanelThresholdStatus.draft) }
    }
}
