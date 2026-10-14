@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultForecastTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPendingResultForecast("code-278", label: "label-774")
        #expect(item.status == Labs.PendingResultForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newPendingResultForecast("code-278", label: "label-774")
        try item.moveTo(Labs.PendingResultForecastStatus.withdrawn)
        #expect(item.status == Labs.PendingResultForecastStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPendingResultForecast("code-278", label: "label-774")
        item.status = Labs.PendingResultForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultForecastStatus.proposed) }
    }
}
