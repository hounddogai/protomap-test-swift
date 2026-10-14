@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScoreTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelScore("code-788", title: "title-62")
        #expect(item.status == Labs.PanelScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newPanelScore("code-788", title: "title-62")
        try item.moveTo(Labs.PanelScoreStatus.completed)
        #expect(item.status == Labs.PanelScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelScore("code-788", title: "title-62")
        item.status = Labs.PanelScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelScoreStatus.planned) }
    }
}
