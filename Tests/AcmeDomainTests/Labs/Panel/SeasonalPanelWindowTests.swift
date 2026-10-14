@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelWindowTests {
    @Test func startsInNew() throws {
        let item = Labs.newSeasonalPanelWindow("code-781", name: "name-61")
        #expect(item.status == Labs.SeasonalPanelWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSeasonalPanelWindow("code-781", name: "name-61")
        try item.moveTo(Labs.SeasonalPanelWindowStatus.running)
        #expect(item.status == Labs.SeasonalPanelWindowStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSeasonalPanelWindow("code-781", name: "name-61")
        item.status = Labs.SeasonalPanelWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalPanelWindowStatus.new) }
    }
}
