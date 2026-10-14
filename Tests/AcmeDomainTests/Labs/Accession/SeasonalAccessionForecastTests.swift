@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionForecastTests {
    @Test func startsInRequested() throws {
        let item = Labs.newSeasonalAccessionForecast("code-12", label: "label-766")
        #expect(item.status == Labs.SeasonalAccessionForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newSeasonalAccessionForecast("code-12", label: "label-766")
        try item.moveTo(Labs.SeasonalAccessionForecastStatus.granted)
        #expect(item.status == Labs.SeasonalAccessionForecastStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newSeasonalAccessionForecast("code-12", label: "label-766")
        item.status = Labs.SeasonalAccessionForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalAccessionForecastStatus.requested) }
    }
}
