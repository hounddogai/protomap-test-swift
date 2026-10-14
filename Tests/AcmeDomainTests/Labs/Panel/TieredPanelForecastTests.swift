@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelForecastTests {
    @Test func startsInProposed() throws {
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        #expect(item.status == Labs.TieredPanelForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        try item.moveTo(Labs.TieredPanelForecastStatus.rejected)
        #expect(item.status == Labs.TieredPanelForecastStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        item.status = Labs.TieredPanelForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredPanelForecastStatus.proposed) }
    }
}
