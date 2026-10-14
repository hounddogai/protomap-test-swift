@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultForecastTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        #expect(item.status == Labs.LegacyResultForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        try item.moveTo(Labs.LegacyResultForecastStatus.resolved)
        #expect(item.status == Labs.LegacyResultForecastStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        item.status = Labs.LegacyResultForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyResultForecastStatus.`open`) }
    }
}
