@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelScoreTests {
    @Test func startsInNew() throws {
        let item = Labs.newSeasonalPanelScore("code-810", name: "name-327")
        #expect(item.status == Labs.SeasonalPanelScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSeasonalPanelScore("code-810", name: "name-327")
        try item.moveTo(Labs.SeasonalPanelScoreStatus.running)
        #expect(item.status == Labs.SeasonalPanelScoreStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSeasonalPanelScore("code-810", name: "name-327")
        item.status = Labs.SeasonalPanelScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalPanelScoreStatus.new) }
    }
}
